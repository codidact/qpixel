class PostHistoryController < ApplicationController
  def post
    @post = Post.find(params[:id])

    unless @post.can_access?(current_user)
      return not_found
    end

    @history = PostHistory.where(post_id: params[:id]).includes(:post_history_type, :user, post_history_tags: [:tag])
                          .order(created_at: :desc).paginate(per_page: 20, page: params[:page])
    render layout: 'without_sidebar'
  end

  def rollback
    @post = Post.find(params[:post_id])
    @history = PostHistory.find(params[:id])
    histories = @post.post_histories.order(created_at: :asc).ids
    index = histories.index(@history.id) + 1

    unless @history.can_rollback?
      flash[:danger] = 'You cannot rollback this particular history element.'
      redirect_to post_history_url(@post)
      return
    end

    # TODO Remove from the hash the elements that we did not change (the ones that are nil)?
    opts = {
      before: @post.body_markdown, after: @history.before_state,
      before_title: @post.title, after_title: @history.before_title,
      before_tags: @post.tags.to_a, after_tags: @history.before_tags.to_a,
      comment: "Rollback of [##{index}: #{@history.post_history_type.name}](#{post_history_url(@post, anchor: index)})"
    }

    # Do the actual rollback
    if rollback_post_history
      Rails.logger.info("\n\n\nSuccessfull rollback!")
    else
      flash[:danger] = 'Unable to rollback revision! #{@post.errors.full_messages.join(', ')}'
      redirect_to post_history_path(@post)
      return
    end

    # Record in the history that this element was rolled back
    new_history = PostHistory.history_rolled_back(@post, current_user, **opts)

    # Store that the previous history was rolled back
    # TODO Add migration
    @history.update(rolled_back_with: new_history)

    Rails.logger.info("\n\n\n #{@history.id} #{@history}")

    nops
    flash[:success] = 'History successfully rolled back'
    redirect_to post_history_path(@post)
  end

  private

  def rollback_post_history
    case @history.post_history_type.name
    when 'post_deleted'
      @post.update(deleted: false, deleted_at: nil, deleted_by: nil,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'post_undeleted'
      predecessor = find_predecessor('post_deleted')
      @post.update(deleted: true, deleted_at: predecessor.created_at, deleted_by: predecessor.user,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'question_closed'
      @post.update(closed: false, closed_by: nil, closed_at: nil, close_reason: nil, duplicate_post: nil,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'question_reopened'
      predecessor = find_predecessor('question_closed')
      # TODO We need to find the close reason properly, this doesn't exist
      @post.update(closed: true, closed_by: predecessor.user, closed_at: predecessor.created_at,
                   close_reason: predecessor.close_reason, duplicate_post: nil,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'post_edited'
      @post.title = @history.before_title if @history.before_title
      @post.body_markdown = @history.before_state if @history.before_state
      @post.body = ApplicationController.helpers.render_markdown(@history.before_state) if @history.before_state
      @post.tags_cache += @history.tags_removed.map(&:name)
      @post.tags_cache -= @history.tags_added.map(&:name)
      @post.last_activity = DateTime.now
      @post.last_activity_by = current_user
      @post.save
    else
      false
    end
  end

  def find_predecessor(type)
    # TODO Test if correct
    @post.post_histories
         .where(post_history_type: PostHistoryType.find(name: type).id)
         .where(created_at: ..@history.created_at)
         .order(created_at: :desc)
         .first
  end
end
