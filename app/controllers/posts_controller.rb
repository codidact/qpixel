# rubocop:disable Metrics/ClassLength
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:document, :share_q, :share_a, :help_center, :show]
  before_action :set_post, only: [:toggle_comments, :feature, :lock, :unlock]
  before_action :set_scoped_post, only: [:change_category, :show, :edit, :update]
  before_action :verify_moderator, only: [:toggle_comments]
  before_action :edit_checks, only: [:edit, :update]

  def new
    @post_type = PostType.find(params[:post_type])
    @category = params[:category].present? ? Category.find(params[:category]) : nil
    @parent = Post.where(id: params[:parent]).first
    @post = Post.new(category: @category, post_type: @post_type, parent: @parent)

    if @post_type.has_category? && @category.nil? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_category', type: @post_type.name)
      redirect_back fallback_location: root_path
    end

    if @post_type.has_parent? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_parent', type: @post_type.name)
      redirect_back fallback_location: root_path
    end
  end

  def create
    @post_type = PostType.find(params[:post][:post_type_id])
    @parent = Post.where(id: params[:parent]).first
    @category = if @post_type.has_category
                  if params[:post][:category_id].present?
                    Category.find(params[:post][:category_id])
                  elsif @parent.present?
                    @parent.category
                  end
                end || nil
    @post = Post.new(post_params.merge(user: current_user, body: helpers.post_markdown(:post, :body_markdown),
                                       category: @category, post_type: @post_type, parent: @parent))

    if @post_type.has_category? && @category.nil? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_category', type: @post_type.name)
      redirect_back fallback_location: root_path
    end

    if @post_type.has_parent? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_parent', type: @post_type.name)
      redirect_back fallback_location: root_path
    end

    if @category.present? && @category.min_trust_level.present? && @category.min_trust_level > current_user.trust_level
      @post.errors.add(:base, helpers.i18ns('posts.category_low_trust_level', category: @category.name))
      render :new, status: 403
      return
    end

    if ['HelpDoc', 'PolicyDoc'].include? @post_type.name
      check_permissions || return
    end

    level_name = @post_type.is_top_level? ? 'TopLevel' : 'SecondLevel'
    level_type_ids = @post_type.is_top_level? ? top_level_post_types : second_level_post_types
    recent_level_posts = Post.where(created_at: 24.hours.ago..Time.now, user: current_user)
                             .where(post_type_id: level_type_ids).count
    setting_name = current_user.privilege?('unrestricted') ? "RL_#{level_name}Posts" : "RL_NewUser#{level_name}Posts"
    max_posts = SiteSetting[setting_name]
    limit_msg = if current_user.privilege?('unrestricted')
                  helpers.i18ns('rate_limit.posts', count: max_posts, level: level_name.underscore.humanize.downcase)
                else
                  helpers.i18ns('rate_limit.new_user_posts',
                                count: max_posts, level: level_name.underscore.humanize.downcase)
                end

    if recent_level_posts >= max_posts
      @post.errors.add :base, limit_msg
      AuditLog.rate_limit_log(event_type: "#{level_name.underscore}_post", related: @category, user: current_user,
                              comment: "limit: #{max_posts}\n\npost:\n#{@post.attributes_print}")
      render :new, status: 403
      return
    end

    if @post.save
      redirect_to helpers.generic_show_link(@post)
    else
      render :new, status: 400
    end
  end

  def show
    if @post.parent_id.present?
      return redirect_to post_path(@post.parent_id)
    end

    if @post.deleted? && !current_user&.has_post_privilege?('flag_curate', @post)
      return not_found
    end

    @children = if current_user&.privilege?('flag_curate')
                  Post.where(parent_id: @post.id)
                else
                  Post.where(parent_id: @post.id).undeleted
                      .or(Post.where(parent_id: @post.id, user_id: current_user&.id))
                end.includes(:votes, :user, :comments, :license, :post_type)
                .user_sort({ term: params[:sort], default: Arel.sql('deleted ASC, score DESC, RAND()') },
                           score: Arel.sql('deleted ASC, score DESC, RAND()'), age: :created_at)
                .paginate(page: params[:page], per_page: 20)
  end

  def edit; end

  def update
    before = { body: @post.body_markdown, title: @post.title, tags: @post.tags }
    after_tags = if @post_type.has_category?
                   Tag.where(tag_set_id: @post.category.tag_set_id, name: params[:post][:tags_cache])
                 end
    body_rendered = helpers.post_markdown(:post, :body)
    new_tags_cache = params[:question][:tags_cache]&.reject(&:empty?)

    if edit_post_params.all? { |k, v| @post.send(k) == v }
      flash[:danger] = "No changes were saved because you didn't edit the post."
      return redirect_to post_path(@post)
    end

    if current_user.privilege?('edit_posts')
      if @post.update(edit_post_params.merge(body: body_rendered,
                                             last_edited_at: DateTime.now, last_edited_by: current_user,
                                             last_activity: DateTime.now, last_activity_by: current_user))
        PostHistory.post_edited(@post, current_user, before: before[:body],
                                after: @post.body_markdown, comment: params[:edit_comment],
                                before_title: before[:title], after_title: @post.title,
                                before_tags: before[:tags], after_tags: after_tags)
      else
        render :edit, status: 400
      end
    else
      new_user = !current_user.privilege?('unrestricted')
      rate_limit = SiteSetting["RL_#{new_user ? 'NewUser' : ''}SuggestedEdits"]
      recent_edits = SuggestedEdit.where(user: current_user, active: true).where('created_at > ?', 24.hours.ago).count
      if recent_edits >= rate_limit
        key = new_user ? 'rate_limit.new_user_suggested_edits' : 'rate_limit.suggested_edits'
        msg = helpers.i18ns key, count: rate_limit
        @post.errors.add :base, msg
        render :edit, status: 403
      else
        data = {
          post: @post,
          user: current_user,
          body: body_rendered == @post.body ? nil : body_rendered,
          title: params[:post][:title] == @post.title ? nil : params[:post][:title],
          tags_cache: new_tags_cache == @post.tags_cache ? @post.tags_cache : new_tags_cache,
          body_markdown: params[:post][:body_markdown] == @post.body_markdown ? nil : params[:post][:body_markdown],
          comment: params[:edit_comment],
          active: true, accepted: false
        }
        edit = SuggestedEdit.new(data)
        if edit.save
          message = "Edit suggested on your #{@post_type.name.underscore.humanize.downcase}"
          if @post_type.has_parent
            message += " on '#{@post.parent.title}'"
          end
          @post.user.create_notification message, suggested_edit_path(edit)
          redirect_to post_path(@post)
        else
          @post.errors = edit.errors
          render :edit, status: 400
        end
      end
    end
  end

  # TODO: delete, undelete, close, reopen

  def document
    @post = Post.unscoped.where(doc_slug: params[:slug], community_id: [RequestContext.community_id, nil]).first
    not_found && return if @post.nil?

    if @post&.help_category == '$Disabled'
      not_found
    end
    if @post&.help_category == '$Moderator' && !current_user&.is_moderator
      not_found
    end
  end

  def upload
    content_types = ActiveStorage::Variant::WEB_IMAGE_CONTENT_TYPES
    extensions = content_types.map { |ct| ct.gsub('image/', '') }
    unless helpers.valid_image?(params[:file])
      render json: { error: "Images must be one of #{extensions.join(', ')}" }, status: 400
      return
    end
    @blob = ActiveStorage::Blob.create_after_upload!(io: params[:file], filename: params[:file].original_filename,
                                                     content_type: params[:file].content_type)
    render json: { link: uploaded_url(@blob.key) }
  end

  def share_q
    redirect_to question_path(id: params[:id])
  end

  def share_a
    redirect_to question_path(id: params[:qid], anchor: "answer-#{params[:id]}")
  end

  def help_center
    @posts = Post.where(post_type_id: [PolicyDoc.post_type_id, HelpDoc.post_type_id])
                 .or(Post.unscoped.where(post_type_id: [PolicyDoc.post_type_id, HelpDoc.post_type_id],
                                         community_id: nil))
                 .where(Arel.sql("posts.help_category IS NULL OR posts.help_category != '$Disabled'"))
                 .order(:help_ordering, :title)
                 .group_by(&:post_type_id)
                 .transform_values { |posts| posts.group_by { |p| p.help_category.present? ? p.help_category : nil } }
  end

  def change_category
    @target = Category.find params[:target_id]
    unless helpers.can_change_category(current_user, @target)
      render json: { success: false, errors: ["You don't have permission to make that change."] }, status: 403
      return
    end

    unless @target.post_type_ids.include? @post.post_type_id
      render json: { success: false, errors: ["This post type is not allowed in the #{@target.name} category."] },
             status: 409
      return
    end

    before = @post.category
    @post.category = @target
    new_tags = @post.tags.map do |tag|
      existing = Tag.where(tag_set: @target.tag_set, name: tag.name).first
      existing.nil? ? Tag.create(tag_set: @target.tag_set, name: tag.name) : existing
    end
    @post.tags = new_tags
    @post.save
    AuditLog.action_audit(event_type: 'change_category', related: @post, user: current_user,
                          comment: "from <<#{before.id}>>\nto <<#{@target.id}>>")
    render json: { success: true }
  end

  def toggle_comments
    @post.comments_disabled = !@post.comments_disabled
    @post.save
    if @post.comments_disabled && params[:delete_all_comments]
      @post.comments.undeleted.map do |c|
        c.deleted = true
        c.save
      end
    end
    render json: { success: true }
  end

  def lock
    return not_found unless current_user.privilege? 'flag_curate'
    return not_found if @post.locked?

    length = params[:length].present? ? params[:length].to_i : nil
    if length
      if !current_user.is_moderator && length > 30
        length = 30
      end
      end_date = length.days.from_now
    elsif current_user.is_moderator
      end_date = nil
    else
      end_date = 7.days.from_now
    end

    @post.update locked: true, locked_by: current_user,
                 locked_at: DateTime.now, locked_until: end_date
    render json: { success: true }
  end

  def unlock
    return not_found unless current_user.privilege? 'flag_curate'
    return not_found unless @post.locked?
    return not_found if @post.locked_until.nil? && !current_user.is_moderator

    @post.update locked: false, locked_by: nil,
                 locked_at: nil, locked_until: nil
    render json: { success: true }
  end

  def feature
    data = {
      label: @post.parent.nil? ? @post.title : @post.parent.title,
      link: helpers.generic_show_link(@post),
      post: @post,
      active: true
    }
    @link = PinnedLink.create data

    attr = @link.attributes_print
    AuditLog.moderator_audit(event_type: 'pinned_link_create', related: @link, user: current_user,
                            comment: "<<PinnedLink #{attr}>>\n(using moderator tools on post)")
    flash[:success] = 'Post has been featured. Due to caching, it may take some time until the changes apply.'
    render json: { success: true }
  end

  def save_draft
    key = "saved_post.#{current_user.id}.#{params[:path]}"
    saved_at = "saved_post_at.#{current_user.id}.#{params[:path]}"
    RequestContext.redis.set key, params[:post]
    RequestContext.redis.set saved_at, DateTime.now.iso8601
    RequestContext.redis.expire key, 86_400 * 7
    RequestContext.redis.expire saved_at, 86_400 * 7
    render json: { success: true, key: key }
  end

  def delete_draft
    key = "saved_post.#{current_user.id}.#{params[:path]}"
    saved_at = "saved_post_at.#{current_user.id}.#{params[:path]}"
    RequestContext.redis.del key, saved_at
    render json: { success: true }
  end

  private

  def permitted
    [:post_type_id, :category_id, :title, :body_markdown, :license_id, :doc_slug, :help_category, :help_ordering]
  end

  def post_params
    p = params.require(:post).permit(*permitted, tags_cache: [])
    p[:tags_cache] = p[:tags_cache]&.reject { |t| t.empty? }
    p
  end

  def edit_post_params
    p = params.require(:post).permit(*(permitted - [:license_id]), tags_cache: [])
    p[:tags_cache] = p[:tags_cache]&.reject { |t| t.empty? }
    p
  end

  def set_post
    @post = Post.unscoped.find(params[:id])
  end

  def set_scoped_post
    @post = Post.find(params[:id])
  end

  def check_permissions
    if @post.post_type_id == HelpDoc.post_type_id
      verify_moderator
    elsif @post.post_type_id == PolicyDoc.post_type_id
      verify_admin
    else
      not_found
      return false
    end
    true
  end

  def edit_checks
    @category = @post.category
    @parent = @post.parent
    @post_type = @post.post_type

    if @post_type.has_parent? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_parent', type: @post_type.name)
      redirect_back fallback_location: root_path
    end

    if !@post_type.is_public_editable && !(@post.user == current_user || current_user.is_moderator)
      flash[:danger] = helpers.i18ns('posts.not_public_editable')
      redirect_back fallback_location: root_path
    end
  end
end
# rubocop:enable Metrics/ClassLength
