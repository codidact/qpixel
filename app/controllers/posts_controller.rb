class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:document, :share_q, :share_a, :help_center]
  before_action :set_post, only: [:edit_help, :update_help, :toggle_comments, :feature]
  before_action :set_scoped_post, only: [:change_category]
  before_action :check_permissions, only: [:edit_help, :update_help]
  before_action :verify_moderator, only: [:new_help, :create_help, :toggle_comments]

  def new
    @category = Category.find(params[:category_id])
    @post = Post.new(category: @category, post_type_id: params[:post_type_id])
    if @category.min_trust_level.present? && @category.min_trust_level > current_user.trust_level
      flash[:danger] = "You don't have a high enough trust level to post in the #{@category.name} category."
      redirect_back fallback_location: root_path
    end
  end

  def create
    @category = Category.find(params[:category_id])
    @post = Post.new(post_params.merge(category: @category, user: current_user,
                                       post_type_id: params[:post][:post_type_id] || params[:post_type_id],
                                       body: helpers.render_markdown(params[:post][:body_markdown])))

    if @category.min_trust_level.present? && @category.min_trust_level > current_user.trust_level
      @post.errors.add(:base, "You don't have a high enough trust level to post in the #{@category.name} category.")
      render :new, status: 403
      return
    end

    if @post.save
      redirect_to helpers.generic_show_link(@post)
    else
      render :new, status: 400
    end
  end

  def new_help
    @post = Post.new
  end

  def create_help
    setting_regex = /\${(?<setting_name>[^}]+)}/
    params[:post][:body_markdown] = params[:post][:body_markdown].gsub(setting_regex) do |_match|
      setting_name = $LAST_MATCH_INFO&.send(:[], :setting_name)
      if setting_name.nil?
        ''
      else
        SiteSetting[setting_name] || '(No such setting)'
      end
    end
    @post = Post.new(new_post_params.merge(body: helpers.render_markdown(params[:post][:body_markdown]),
                                           user: User.find(-1)))

    if @post.policy_doc? && !current_user&.is_admin
      @post.errors.add(:base, 'You must be an administrator to create a policy document.')
      render :new_help, status: 403
      return
    end

    if @post.save
      redirect_to policy_path(slug: @post.doc_slug)
    else
      render :new_help, status: 500
    end
  end

  def edit_help; end

  def update_help
    setting_regex = /\${(?<setting_name>[^}]+)}/
    params[:post][:body_markdown] = params[:post][:body_markdown].gsub(setting_regex) do |_match|
      setting_name = $LAST_MATCH_INFO&.send(:[], :setting_name)
      if setting_name.nil?
        ''
      else
        SiteSetting[setting_name] || '(No such setting)'
      end
    end
    PostHistory.post_edited(@post, current_user, before: @post.body_markdown, after: params[:post][:body_markdown])
    if @post.update(help_post_params.merge(body: helpers.render_markdown(params[:post][:body_markdown]),
                                           last_activity: DateTime.now, last_activity_by: current_user))
      redirect_to policy_path(slug: @post.doc_slug)
    else
      render :edit_help, status: 500
    end
  end

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
    if @post.comments_disabled
      if params[:delete_all_comments]
        @post.comments.undeleted.map do |c|
          c.deleted = true
          c.save
        end
      end
    end
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

    attr = @link.attributes.map { |k, v| "#{k}: #{v}" }.join(' ')
    AuditLog.moderator_audit(event_type: 'pinned_link_create', related: @link, user: current_user,
                            comment: "<<PinnedLink #{attr}>>\n(using moderator tools on post)")
    flash[:success] = 'Post has been featured. Due to caching it may take some time, until the changes apply.'
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

  def new_post_params
    params.require(:post).permit(:post_type_id, :title, :doc_slug, :help_category, :body_markdown, :help_ordering)
  end

  def help_post_params
    params.require(:post).permit(:title, :help_category, :body_markdown, :help_ordering)
  end

  def post_params
    p = params.require(:post).permit(:title, :body_markdown, :post_type_id, :license_id, tags_cache: [])
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
    end
  end
end
