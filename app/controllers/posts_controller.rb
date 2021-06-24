# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:document, :help_center, :show]
  before_action :set_post, only: [:toggle_comments, :feature, :lock, :unlock]
  before_action :set_scoped_post, only: [:change_category, :show, :edit, :update, :close, :reopen, :delete, :restore]
  before_action :verify_moderator, only: [:toggle_comments]
  before_action :edit_checks, only: [:edit, :update]
  before_action :unless_locked, only: [:edit, :update, :close, :reopen, :delete, :restore]

  def new
    @post_type = PostType.find(params[:post_type])
    @category = params[:category].present? ? Category.find(params[:category]) : nil
    @parent = Post.where(id: params[:parent]).first
    @post = Post.new(category: @category, post_type: @post_type, parent: @parent)

    if @post_type.has_parent? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_parent', type: @post_type.name)
      redirect_back fallback_location: root_path
      return
    end

    if @post_type.has_category? && @category.nil? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_category', type: @post_type.name)
      redirect_back fallback_location: root_path
      return
    end

    if ['HelpDoc', 'PolicyDoc'].include?(@post_type.name)
      check_permissions
      # return # uncomment if you add more code after this
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

    if @post_type.has_parent? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_parent', type: @post_type.name)
      redirect_back fallback_location: root_path
      return
    end

    if @post_type.has_category? && @category.nil? && @parent.nil?
      flash[:danger] = helpers.i18ns('posts.type_requires_category', type: @post_type.name)
      redirect_back fallback_location: root_path
      return
    end

    if @category.present? && @category.min_trust_level.present? && @category.min_trust_level > current_user.trust_level
      @post.errors.add(:base, helpers.i18ns('posts.category_low_trust_level', category: @category.name))
      render :new, status: :forbidden
      return
    end

    if ['HelpDoc', 'PolicyDoc'].include?(@post_type.name) && !check_permissions
      return
    end

    level_name = @post_type.is_top_level? ? 'TopLevel' : 'SecondLevel'
    level_type_ids = @post_type.is_top_level? ? top_level_post_types : second_level_post_types
    recent_level_posts = Post.where(created_at: 24.hours.ago..DateTime.now, user: current_user)
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
      render :new, status: :forbidden
      return
    end

    if @post.save
      if @post_type.has_parent?
        unless @post.user_id == @post.parent.user_id
          @post.parent.user.create_notification("New response to your post #{@post.parent.title}",
                                                helpers.generic_show_link(@post))
        end
        @post.parent.update(last_activity: DateTime.now, last_activity_by: current_user)
      end

      ['p', '1', '2'].each do |key|
        Rails.cache.delete "community_user/#{current_user.community_user.id}/metric/#{key}"
      end
      redirect_to helpers.generic_show_link(@post)
    else
      render :new, status: :bad_request
    end
  end

  def show
    if @post.parent_id.present?
      return redirect_to post_path(@post.parent_id)
    end

    if @post.post_type_id == HelpDoc.post_type_id
      redirect_to help_path(@post.doc_slug)
    elsif @post.post_type_id == PolicyDoc.post_type_id
      redirect_to policy_path(@post.doc_slug)
    end

    if @post.deleted? && !current_user&.has_post_privilege?('flag_curate', @post)
      return not_found
    end

    @top_level_post_types = top_level_post_types
    @second_level_post_types = second_level_post_types

    if @post.category_id.present? && @post.category.min_view_trust_level.present? && \
       (!user_signed_in? || current_user.trust_level < @post.category.min_view_trust_level) && \
       @post.category.min_view_trust_level.positive?
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
    before = { body: @post.body_markdown, title: @post.title, tags: @post.tags.to_a }
    body_rendered = helpers.post_markdown(:post, :body_markdown)
    new_tags_cache = params[:post][:tags_cache]&.reject(&:empty?)

    if edit_post_params.to_h.all? { |k, v| @post.send(k) == v }
      flash[:danger] = helpers.i18ns('posts.no_edit_changes')
      return redirect_to post_path(@post)
    end

    if current_user.privilege?('edit_posts') || current_user.is_moderator || current_user == @post.user || \
       (@post_type.is_freely_editable && current_user.privilege?('unrestricted'))
      if @post.update(edit_post_params.merge(body: body_rendered,
                                             last_edited_at: DateTime.now, last_edited_by: current_user,
                                             last_activity: DateTime.now, last_activity_by: current_user))
        PostHistory.post_edited(@post, current_user, before: before[:body],
                                after: @post.body_markdown, comment: params[:edit_comment],
                                before_title: before[:title], after_title: @post.title,
                                before_tags: before[:tags], after_tags: @post.tags)
        Rails.cache.delete "community_user/#{current_user.community_user.id}/metric/E"
        redirect_to post_path(@post)
      else
        render :edit, status: :bad_request
      end
    else
      new_user = !current_user.privilege?('unrestricted')
      rate_limit = SiteSetting["RL_#{new_user ? 'NewUser' : ''}SuggestedEdits"]
      recent_edits = SuggestedEdit.where(user: current_user, active: true).where('created_at > ?', 24.hours.ago).count
      if recent_edits >= rate_limit
        key = new_user ? 'rate_limit.new_user_suggested_edits' : 'rate_limit.suggested_edits'
        msg = helpers.i18ns key, count: rate_limit
        @post.errors.add :base, msg
        render :edit, status: :forbidden
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
          @post.user.create_notification message, suggested_edit_url(edit, host: @post.community.host)
          redirect_to post_path(@post)
        else
          @post.errors = edit.errors
          render :edit, status: :bad_request
        end
      end
    end
  end

  def close
    unless check_your_privilege('flag_close', nil, false) || @post.user.id == current_user.id
      render json: { status: 'failed', message: helpers.ability_err_msg(:flag_close, 'close this post') },
             status: :forbidden
      return
    end

    if @post.closed
      render json: { status: 'failed', message: 'Cannot close a closed post.' }, status: :bad_request
      return
    end

    reason = CloseReason.find_by id: params[:reason_id]
    if reason.nil?
      render json: { status: 'failed', message: 'Close reason not found.' }, status: :not_found
      return
    end

    if reason.requires_other_post
      other = Post.find_by(id: params[:other_post])
      if other.nil? || !top_level_post_types.include?(other.post_type_id)
        render json: { status: 'failed', message: 'Invalid input for other post.' }, status: :bad_request
        return
      end

      if other == @post
        render json: { status: 'failed', message: 'You can not close a post as a duplicate of itself' },
               status: :bad_request
        return
      end

      duplicate_of = Question.find(params[:other_post])
    else
      duplicate_of = nil
    end

    if @post.update(closed: true, closed_by: current_user, closed_at: DateTime.now, last_activity: DateTime.now,
                    last_activity_by: current_user, close_reason: reason, duplicate_post: duplicate_of)
      PostHistory.question_closed(@post, current_user)
      render json: { status: 'success' }
    else
      render json: { status: 'failed', message: helpers.i18ns('posts.cant_close_post'),
                     errors: @post.errors.full_messages }
    end
  end

  def reopen
    unless check_your_privilege('flag_close', nil, false)
      flash[:danger] = helpers.ability_err_msg(:flag_close, 'reopen this post')
      redirect_to post_path(@post)
      return
    end

    unless @post.closed
      flash[:danger] = helpers.i18ns('posts.already_opened')
      redirect_to post_path(@post)
      return
    end

    if @post.update(closed: false, closed_by: current_user, closed_at: DateTime.now,
                    last_activity: DateTime.now, last_activity_by: current_user,
                    close_reason: nil, duplicate_post: nil)
      PostHistory.question_reopened(@post, current_user)
    else
      flash[:danger] = helpers.i18ns('posts.cant_reopen_post')
    end
    redirect_to post_path(@post)
  end

  def delete
    unless check_your_privilege('flag_curate', @post, false)
      flash[:danger] = helpers.ability_err_msg(:flag_curate, 'delete this post')
      redirect_to post_path(@post)
      return
    end

    if @post.children.any? { |a| a.score >= 0.5 } && !current_user&.is_moderator
      flash[:danger] = helpers.i18ns('posts.cant_delete_responded')
      redirect_to post_path(@post)
      return
    end

    if @post.deleted
      flash[:danger] = helpers.i18ns('posts.already_deleted')
      redirect_to post_path(@post)
      return
    end

    if @post.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                    last_activity: DateTime.now, last_activity_by: current_user)
      PostHistory.post_deleted(@post, current_user)
      if @post.children.where(deleted: false).any?
        @post.children.where(deleted: false).update_all(deleted: true, deleted_at: DateTime.now,
                                                        deleted_by_id: current_user.id, last_activity: DateTime.now,
                                                        last_activity_by_id: current_user.id)
        histories = @post.children.map do |c|
          { post_history_type: PostHistoryType.find_by(name: 'post_deleted'), user: current_user, post: c,
            community: RequestContext.community }
        end
        PostHistory.create(histories)
      end
    else
      flash[:danger] = helpers.i18ns('posts.cant_delete_post')
    end

    redirect_to post_path(@post)
  end

  def restore
    unless check_your_privilege('flag_curate', @post, false)
      flash[:danger] = helpers.ability_err_msg(:flag_curate, 'restore this post')
      redirect_to post_path(@post)
      return
    end

    unless @post.deleted
      flash[:danger] = helpers.i18ns('posts.cant_restore_undeleted')
      redirect_to post_path(@post)
      return
    end

    if @post.deleted_by.is_moderator && !current_user.is_moderator
      flash[:danger] = helpers.i18ns('posts.cant_restore_deleted_by_moderator')
      redirect_to post_path(@post)
      return
    end

    deleted_at = @post.deleted_at
    if @post.update(deleted: false, deleted_at: nil, deleted_by: nil,
                    last_activity: DateTime.now, last_activity_by: current_user)
      PostHistory.post_undeleted(@post, current_user)
      restore_children = @post.children.where('deleted_at >= ?', deleted_at)
                              .where('deleted_at <= ?', deleted_at + 5.seconds)
      restore_children.update_all(deleted: false, last_activity: DateTime.now, last_activity_by_id: current_user.id)
      histories = restore_children.map do |c|
        { post_history_type: PostHistoryType.find_by(name: 'post_undeleted'), user: current_user, post: c,
          community: RequestContext.community }
      end
      PostHistory.create(histories)
    else
      flash[:danger] = helpers.i18ns('posts.cant_restore_post')
    end

    redirect_to post_path(@post)
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
      render json: { error: "Images must be one of #{extensions.join(', ')}" }, status: :bad_request
      return
    end
    @blob = ActiveStorage::Blob.create_after_upload!(io: params[:file], filename: params[:file].original_filename,
                                                     content_type: params[:file].content_type)
    render json: { link: uploaded_url(@blob.key) }
  end

  def help_center
    @posts = Post.where(post_type_id: [PolicyDoc.post_type_id, HelpDoc.post_type_id])
                 .or(Post.unscoped.where(post_type_id: [PolicyDoc.post_type_id, HelpDoc.post_type_id],
                                         community_id: nil))
                 .where(Arel.sql("posts.help_category IS NULL OR posts.help_category != '$Disabled'"))
                 .order(:help_ordering, :title)
                 .group_by(&:post_type_id)
                 .transform_values { |posts| posts.group_by { |p| p.help_category.presence } }
  end

  def change_category
    @target = Category.find params[:target_id]
    unless helpers.can_change_category(current_user, @target)
      render json: { success: false, errors: [helpers.i18ns('posts.cant_change_category')] }, status: :forbidden
      return
    end

    unless @target.post_type_ids.include? @post.post_type_id
      render json: { success: false, errors: [helpers.i18ns('posts.type_not_included', type: @target.name)] },
             status: :conflict
      return
    end

    before = @post.category
    @post.category = @target
    new_tags = @post.tags.map do |tag|
      existing = Tag.where(tag_set: @target.tag_set, name: tag.name).first
      existing.nil? ? Tag.create(tag_set: @target.tag_set, name: tag.name) : existing
    end
    @post.tags = new_tags
    success = @post.save
    AuditLog.action_audit(event_type: 'change_category', related: @post, user: current_user,
                          comment: "from <<#{before.id}: #{before.name}>>\nto <<#{@target.id}: #{@target.name}>>")
    render json: { success: success, errors: success ? [] : @post.errors.full_messages }, status: success ? 200 : 409
  end

  def toggle_comments
    @post.update(comments_disabled: !@post.comments_disabled)
    if @post.comments_disabled && params[:delete_all_comments]
      @post.comments.update_all(deleted: true)
      @post.comment_threads.update_all(deleted: true, deleted_by_id: current_user.id, reply_count: 0)
    end
    render json: { status: 'success', success: true }
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
    render json: { status: 'success', success: true }
  end

  def unlock
    return not_found(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'
    return not_found(errors: ['not_locked']) unless @post.locked?
    if @post.locked_by.is_moderator && !current_user.is_moderator
      return not_found(errors: ['locked_by_mod'])
    end

    @post.update locked: false, locked_by: nil,
                 locked_at: nil, locked_until: nil
    render json: { status: 'success', success: true }
  end

  def feature
    return not_found(errors: ['no_privilege']) unless current_user.is_moderator

    data = {
      label: @post.parent.nil? ? @post.title : @post.parent.title,
      link: helpers.generic_show_link(@post),
      post: @post,
      active: true,
      community: RequestContext.community
    }
    @link = PinnedLink.create data

    attr = @link.attributes_print
    AuditLog.moderator_audit(event_type: 'pinned_link_create', related: @link, user: current_user,
                             comment: "<<PinnedLink #{attr}>>\n(using moderator tools on post)")
    flash[:success] = helpers.i18ns('posts.post_has_been_featured')
    render json: { status: 'success', success: true }
  end

  def save_draft
    key = "saved_post.#{current_user.id}.#{params[:path]}"
    saved_at = "saved_post_at.#{current_user.id}.#{params[:path]}"
    RequestContext.redis.set key, params[:post]
    RequestContext.redis.set saved_at, DateTime.now.iso8601
    RequestContext.redis.expire key, 86_400 * 7
    RequestContext.redis.expire saved_at, 86_400 * 7
    render json: { status: 'success', success: true, key: key }
  end

  def delete_draft
    key = "saved_post.#{current_user.id}.#{params[:path]}"
    saved_at = "saved_post_at.#{current_user.id}.#{params[:path]}"
    RequestContext.redis.del key, saved_at
    render json: { status: 'success', success: true }
  end

  private

  def permitted
    [:post_type_id, :category_id, :parent_id, :title, :body_markdown, :license_id,
     :doc_slug, :help_category, :help_ordering]
  end

  def post_params
    p = params.require(:post).permit(*permitted, tags_cache: [])
    p[:tags_cache] = p[:tags_cache]&.reject { |t| t.empty? }
    p
  end

  def edit_post_params
    p = params.require(:post).permit(*(permitted - [:license_id, :post_type_id, :category_id, :parent_id]),
                                     tags_cache: [])
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

  def unless_locked
    check_if_locked(@post)
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
