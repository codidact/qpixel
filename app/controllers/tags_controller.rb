class TagsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :rename, :merge, :select_merge]
  before_action :set_category, except: [:index]
  before_action :set_tag, only: [:show, :edit, :update, :children, :rename, :merge, :select_merge, :nuke, :nuke_warning]
  before_action :verify_tag_editor, only: [:new, :create]
  before_action :verify_moderator, only: [:rename, :merge, :select_merge]
  before_action :verify_admin, only: [:nuke, :nuke_warning]

  def index
    @tag_set = if params[:tag_set].present?
                 TagSet.find(params[:tag_set])
               end
    @tags = if params[:term].present?
              (@tag_set&.tags || Tag).search(params[:term])
            else
              (@tag_set&.tags || Tag.all).order(:name)
            end.includes(:tag_synonyms).paginate(page: params[:page], per_page: 50)
    respond_to do |format|
      format.json do
        render json: @tags.to_json(include: { tag_synonyms: { only: :name } })
      end
    end
  end

  def category
    @tag_set = @category.tag_set
    @tags = if params[:q].present?
              @tag_set.tags.search(params[:q])
            elsif params[:hierarchical].present?
              @tag_set.tags_with_paths.order(:path)
            elsif params[:no_excerpt].present?
              @tag_set.tags.where(excerpt: '').or(@tag_set.tags.where(excerpt: nil))
                      .order(Arel.sql('COUNT(posts.id) DESC'))
            else
              @tag_set.tags.order(Arel.sql('COUNT(posts.id) DESC'))
            end
    @count = @tags.count
    table = params[:hierarchical].present? ? 'tags_paths' : 'tags'
    @tags = @tags.left_joins(:posts).group(Arel.sql("#{table}.id"))
                 .select(Arel.sql("#{table}.*, COUNT(posts.id) AS post_count"))
                 .paginate(per_page: 96, page: params[:page])
  end

  def show
    sort_params = { activity: { last_activity: :desc }, age: { created_at: :desc }, score: { score: :desc },
                    native: Arel.sql('att_source IS NULL DESC, last_activity DESC') }
    sort_param = sort_params[params[:sort]&.to_sym] || { last_activity: :desc }
    tag_ids = if params[:self].present?
                [@tag.id]
              else
                @tag.all_children + [@tag.id]
              end
    displayed_post_types = @tag.tag_set.categories.map(&:display_post_types).flatten
    @posts = Post.joins(:tags).where(tags: { id: tag_ids })
                 .undeleted.where(post_type_id: displayed_post_types)
                 .includes(:post_type, :tags).list_includes.paginate(page: params[:page], per_page: 50)
                 .order(sort_param)
    respond_to do |format|
      format.html
      format.rss
    end
  end

  def new
    @tag = Tag.new
    @tag.tag_synonyms.build
  end

  def create
    @tag = Tag.new(tag_params.merge(tag_set_id: @category.tag_set.id))
    if @tag.save
      flash[:danger] = nil
      redirect_to tag_path(id: @category.id, tag_id: @tag.id)
    else
      flash[:danger] = @tag.errors.full_messages.join(', ')
      render :new, status: :bad_request
    end
  end

  def edit
    check_your_privilege('edit_tags', nil, true)
    @tag.tag_synonyms.build
  end

  def update
    return unless check_your_privilege('edit_tags', nil, true)

    wiki_md = params[:tag][:wiki_markdown]
    if @tag.update(tag_params.merge(wiki: wiki_md.present? ? helpers.render_markdown(wiki_md) : nil).except(:name))
      redirect_to tag_path(id: @category.id, tag_id: @tag.id)
    else
      render :edit, status: :bad_request
    end
  end

  def children
    @tags = if params[:q].present?
              @tag.children.search(params[:q])
            elsif params[:hierarchical].present?
              @tag.children_with_paths.order(:path)
            else
              @tag.children.order(Arel.sql('COUNT(posts.id) DESC'))
            end
    @count = @tags.count
    table = params[:hierarchical].present? ? 'tags_paths' : 'tags'
    @tags = @tags.left_joins(:posts).group(Arel.sql("#{table}.id"))
                 .select(Arel.sql("#{table}.*, COUNT(posts.id) AS post_count"))
                 .paginate(per_page: 96, page: params[:page])
  end

  def rename
    status = @tag.update(name: params[:name])
    render json: { success: status, tag: @tag }
  end

  def select_merge; end

  def merge
    @primary = @tag

    # No merge to self.
    if params[:merge_with_id] == @primary.id.to_s
      flash[:danger] = 'Cannot merge a tag with itself.'
      redirect_back fallback_location: categories_path
      return
    end

    @subordinate = Tag.find params[:merge_with_id]

    Post.transaction do
      AuditLog.moderator_audit event_type: 'tag_merge', related: @primary, user: current_user, comment:
        "#{@subordinate.name} (#{@subordinate.id}) into #{@primary.name} (#{@primary.id})"

      # Replace subordinate with primary, except when a post already has primary (to avoid giving them a duplicate tag)
      posts_sql = 'UPDATE posts INNER JOIN posts_tags ON posts.id = posts_tags.post_id ' \
                  'SET posts.tags_cache = REPLACE(posts.tags_cache, ?, ?) ' \
                  'WHERE posts_tags.tag_id = ? ' \
                  'AND posts_tags.post_id NOT IN (SELECT post_id FROM posts_tags WHERE tag_id = ?)'
      exec_sql([posts_sql, "\n- #{@subordinate.name}\n", "\n- #{@primary.name}\n", @subordinate.id, @primary.id])

      # Remove the subordinate tag from posts that still have it (the ones that were excluded from our previous query)
      posts2_sql = 'UPDATE posts INNER JOIN posts_tags ON posts.id = posts_tags.post_id ' \
                   'SET posts.tags_cache = REPLACE(posts.tags_cache, ?, ?) ' \
                   'WHERE posts_tags.tag_id = ?'
      exec_sql([posts2_sql, "\n- #{@subordinate.name}\n", "\n", @subordinate.id])

      # Break hierarchies
      tags_sql = 'UPDATE tags SET parent_id = NULL WHERE parent_id = ?'
      exec_sql([tags_sql, @subordinate.id])

      # Remove references to the tag
      sql = 'UPDATE IGNORE $TABLENAME SET tag_id = ? WHERE tag_id = ?'
      exec_sql([sql.gsub('$TABLENAME', 'posts_tags'), @primary.id, @subordinate.id])
      exec_sql([sql.gsub('$TABLENAME', 'categories_moderator_tags'), @primary.id, @subordinate.id])
      exec_sql([sql.gsub('$TABLENAME', 'categories_required_tags'), @primary.id, @subordinate.id])
      exec_sql([sql.gsub('$TABLENAME', 'categories_topic_tags'), @primary.id, @subordinate.id])
      exec_sql([sql.gsub('$TABLENAME', 'post_history_tags'), @primary.id, @subordinate.id])
      exec_sql([sql.gsub('$TABLENAME', 'suggested_edits_tags'), @primary.id, @subordinate.id])
      exec_sql([sql.gsub('$TABLENAME', 'suggested_edits_before_tags'), @primary.id, @subordinate.id])

      # Nuke it from orbit
      @subordinate.destroy
    end

    flash[:success] = "Merged #{@subordinate.name} into #{@primary.name}."
    redirect_to tag_path(id: @category.id, tag_id: @primary.id)
  end

  def nuke
    Post.transaction do
      AuditLog.admin_audit event_type: 'tag_nuke', related: @tag, user: current_user,
                           comment: "#{@tag.name} (#{@tag.id})"

      tables = ['posts_tags', 'categories_moderator_tags', 'categories_required_tags', 'categories_topic_tags',
                'post_history_tags', 'suggested_edits_tags', 'suggested_edits_before_tags']

      # Remove tag from caches
      caches_sql = 'UPDATE posts INNER JOIN posts_tags ON posts.id = posts_tags.post_id ' \
                   'SET posts.tags_cache = REPLACE(posts.tags_cache, ?, ?) ' \
                   'WHERE posts_tags.tag_id = ?'
      exec_sql([caches_sql, "\n- #{@tag.name}\n", "\n", @tag.id])

      # Delete all references to the tag
      tables.each do |tbl|
        sql = "DELETE FROM #{tbl} WHERE tag_id = ?"
        exec_sql([sql, @tag.id])
      end

      # Nuke it
      @tag.destroy
    end

    flash[:success] = "Deleted #{@tag.name}"
    redirect_to category_tags_path(@category)
  end

  def nuke_warning; end

  private

  def set_tag
    @tag = Tag.find params[:tag_id]
  end

  def set_category
    @category = Category.find params[:id]
  end

  def tag_params
    params.require(:tag).permit(:excerpt, :wiki_markdown, :parent_id, :name,
                                tag_synonyms_attributes: [:id, :name, :_destroy])
  end

  def exec_sql(sql_array)
    ApplicationRecord.connection.execute(ActiveRecord::Base.sanitize_sql_array(sql_array))
  end

  def verify_tag_editor
    if !user_signed_in? || !(current_user&.privilege?(:edit_tags) || current_user&.is_moderator || current_user&.is_admin)
      respond_to do |format|
        format.html do
          render 'errors/not_found', layout: 'without_sidebar', status: :not_found
        end
        format.json do
          render json: { status: 'failed', success: false, errors: ['not_found'] }, status: :not_found
        end
      end

      return false
    end
    true
  end
end
