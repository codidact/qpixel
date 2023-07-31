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

    msg = helpers.disallow_rollback_history(@history, current_user)
    if msg.present?
      flash[:danger] = "You are not allowed to rollback this history element: #{msg}"
      redirect_to post_history_url(@post)
      return
    end

    opts = {
      before: @post.body_markdown, before_title: @post.title, before_tags: @post.tags.to_a,
      comment: "Rollback of [##{index}: #{@history.post_history_type.name.humanize}]" \
               "(#{post_history_url(@post, anchor: index)})",
      extra: { rollback_of_id: @history.id, rollback_index: index }
    }

    # If we are closing a question, also record the close reason from the original history item
    rollback_type = @history.post_history_type.name_inverted
    if rollback_type == 'question_closed'
      opts[:extra][:close_reason_id] = @history.extra&.fetch('close_reason_id', nil)
      opts[:extra][:duplicate_post_id] = @history.extra&.fetch('duplicate_post_id', nil)
    end

    PostHistory.transaction do
      unless rollback_post_history
        flash[:danger] = "Unable to rollback revision: #{@post.errors.full_messages.join(', ')}"
        redirect_to post_history_path(@post)
        return
      end

      opts = opts.merge(after: @post.body_markdown, after_title: @post.title, after_tags: @post.tags.to_a)

      # Record in the history that this element was rolled back
      new_history = PostHistory.send(rollback_type, @post, current_user, **opts)

      # Set the original to be rolled back
      @history.extra = {} unless @history.extra
      @history.extra[:rolled_back_with] = new_history.id
      @history.save!
    end

    flash[:success] = 'History successfully rolled back'
    redirect_to post_history_path(@post)
  end

  def revert_to
    @post = Post.find(params[:post_id])
    @history = PostHistory.find(params[:id])
    after_histories = @post.post_histories
                           .where(created_at: @history.created_at..)
                           .where.not(id: @history.id)
                           .includes(:post_history_type)
                           .order(created_at: :desc, id: :desc)

    to_change = {}
    after_histories.each do |ph|
      case ph.post_history_type.name
      when 'post_undeleted'
        to_change[:deleted] = true
      when 'post_deleted'
        to_change[:deleted] = false
      when 'question_reopened'
        to_change[:closed] = true
      when 'question_closed'
        to_change[:closed] = false
      when 'post_edited'
        to_change[:title] = ph.before_title if ph.before_title.present?
        to_change[:body] = ph.before_state if ph.before_state.present?
        to_change[:tags] = ph.before_tags if ph.before_tags.present?
      end
    end

    # Recover post close reason from predecessor of last reopened
    if to_change[:closed]
      ph = find_predecessor('question_closed', after_histories.last)
      to_change[:close_reason_id] ||= ph.extra&.fetch('close_reason_id', nil)
      to_change[:duplicate_post_id] ||= ph.extra&.fetch('duplicate_post_id', nil)
    end

    revert_comment = "Reverting to [##{index}: #{@history.post_history_type.name.humanize}]" \
                     "(#{post_history_url(@post, anchor: index)})"

    # Perform edit
    if to_change[:title].present? || to_change[:body].present? || to_change[:tags].present?
      opts = {
        before: @post.body_markdown, before_title: @post.title, before_tags: @post.tags.to_a,
        comment: revert_comment
      }

      @post.title = to_change[:title] if to_change[:title].present?
      if to_change[:body].present?
        @post.body_markdown = to_change[:body]
        @post.body = ApplicationController.helpers.render_markdown(to_change[:body])
      end
      @post.tags_cache = to_change[:tags].map(&:name) if to_change[:tags].present?
      @post.last_activity = DateTime.now
      @post.last_activity_by = current_user
      @post.save

      opts = opts.merge(after: @post.body_markdown, after_title: @post.title, after_tags: @post.tags.to_a)

      PostHistory.post_edited(@post, current_user, **opts)
    end

    # Perform reopen
    unless to_change[:closed].nil?
      if to_change[:closed]
        # Close
        @post.update(closed: true, closed_by: current_user, closed_at: DateTime.now,
                     close_reason_id: to_change[:close_reason_id],
                     duplicate_post_id: to_change[:duplicate_post_id],
                     last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.question_closed(@post, current_user, comment: revert_comment,
                                    extra: {
                                      close_reason_id: to_change[:close_reason_id],
                                      duplicate_post_id: to_change[:duplicate_post_id]
                                    })
      else
        # Reopen
        @post.update(closed: false, closed_by: nil, closed_at: nil, close_reason: nil, duplicate_post: nil,
                     last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.question_reopened(@post, current_user, comment: revert_comment)
      end
    end

    unless to_change[:deleted].nil?
      if to_change[:deleted]
        @post.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                     last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.post_deleted(@post, current_user, comment: revert_comment)
      else
        @post.update(deleted: false, deleted_at: nil, deleted_by: nil,
                     last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.post_undeleted(@post, current_user, comment: revert_comment)
      end
    end
  end

  private

  def rollback_post_history
    case @history.post_history_type.name
    when 'post_deleted'
      @post.update(deleted: false, deleted_at: nil, deleted_by: nil,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'post_undeleted'
      predecessor = find_predecessor('post_deleted', @history)
      @post.update(deleted: true, deleted_at: predecessor.created_at, deleted_by: predecessor.user,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'question_closed'
      @post.update(closed: false, closed_by: nil, closed_at: nil, close_reason: nil, duplicate_post: nil,
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'question_reopened'
      predecessor = find_predecessor('question_closed', @history)
      @post.update(closed: true, closed_by: predecessor.user, closed_at: predecessor.created_at,
                   close_reason_id: predecessor.extra&.fetch('close_reason_id', nil),
                   duplicate_post_id: predecessor.extra&.fetch('duplicate_post_id', nil),
                   last_activity: DateTime.now, last_activity_by: current_user)
    when 'post_edited'
      @post.title = @history.before_title if @history.before_title && @history.before_title != @history.after_title
      if @history.before_state && @history.before_state != @history.after_state
        @post.body_markdown = @history.before_state
        @post.body = ApplicationController.helpers.render_markdown(@history.before_state)
      end
      @post.tags_cache += @history.tags_removed.map(&:name)
      @post.tags_cache -= @history.tags_added.map(&:name)
      @post.last_activity = DateTime.now
      @post.last_activity_by = current_user
      @post.save
    else
      false
    end
  end

  def find_predecessor(type, history)
    @post.post_histories
         .where(post_history_type: PostHistoryType.find_by(name: type).id)
         .where(created_at: ..history.created_at)
         .order(created_at: :desc)
         .first
  end
end
