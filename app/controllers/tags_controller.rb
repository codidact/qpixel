class TagsController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :rename, :merge, :select_merge]
  before_action :set_category, except: [:index]
  before_action :set_tag, only: [:show, :edit, :update, :children, :rename, :merge, :select_merge]
  before_action :verify_moderator, only: [:rename, :merge, :select_merge]

  def index
    @tag_set = if params[:tag_set].present?
                 TagSet.find(params[:tag_set])
               end
    @tags = if params[:term].present?
              (@tag_set&.tags || Tag).search(params[:term])
            else
              (@tag_set&.tags || Tag.all).order(:name)
            end.paginate(page: params[:page], per_page: 50)
    respond_to do |format|
      format.json do
        render json: @tags
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
    post_ids = helpers.post_ids_for_tags(tag_ids)
    @posts = Post.where(id: post_ids).undeleted.where(post_type_id: @category.display_post_types)
                 .includes(:post_type, :tags).list_includes.paginate(page: params[:page], per_page: 50)
                 .order(sort_param)
    respond_to do |format|
      format.html
      format.rss
    end
  end

  def edit
    check_your_privilege('edit_tags', nil, true)
  end

  def update
    return unless check_your_privilege('edit_tags', nil, true)

    wiki_md = params[:tag][:wiki_markdown]
    if @tag.update(tag_params.merge(wiki: wiki_md.present? ? helpers.render_markdown(wiki_md) : nil))
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

    # Take the tag off posts
    posts_sql = 'UPDATE posts INNER JOIN posts_tags ON posts.id = posts_tags.post_id ' \
                'SET posts.tags_cache = REPLACE(posts.tags_cache, ?, ?) ' \
                'WHERE posts_tags.tag_id = ?'
    exec([posts_sql, "\n- #{@subordinate.name}", "\n- #{@primary.name}", @subordinate.id])

    # Break hierarchies
    tags_sql = 'UPDATE tags SET parent_id = NULL WHERE parent_id = ?'
    exec([tags_sql, @subordinate.id])

    # Remove references to the tag
    sql = 'UPDATE IGNORE $TABLENAME SET tag_id = ? WHERE tag_id = ?'
    exec([sql.gsub('$TABLENAME', 'posts_tags'), @primary.id, @subordinate.id])
    exec([sql.gsub('$TABLENAME', 'categories_moderator_tags'), @primary.id, @subordinate.id])
    exec([sql.gsub('$TABLENAME', 'categories_required_tags'), @primary.id, @subordinate.id])
    exec([sql.gsub('$TABLENAME', 'categories_topic_tags'), @primary.id, @subordinate.id])
    exec([sql.gsub('$TABLENAME', 'post_history_tags'), @primary.id, @subordinate.id])
    exec([sql.gsub('$TABLENAME', 'suggested_edits_tags'), @primary.id, @subordinate.id])

    # Nuke it from orbit
    @subordinate.destroy

    flash[:success] = "Merged #{@subordinate.name} into #{@primary.name}."
    redirect_to tag_path(id: @category.id, tag_id: @primary.id)
  end

  private

  def set_tag
    @tag = Tag.find params[:tag_id]
  end

  def set_category
    @category = Category.find params[:id]
  end

  def tag_params
    params.require(:tag).permit(:excerpt, :wiki_markdown, :parent_id)
  end

  def exec(sql_array)
    ApplicationRecord.connection.execute(ActiveRecord::Base.sanitize_sql_array(sql_array))
  end
end
