class PostHistoryController < ApplicationController
  def post
    @post = Post.find(params[:id])

    unless @post.can_access?(current_user)
      return not_found
    end

    @history = PostHistory.where(post_id: params[:id])
                          .includes(:post_history_type, :user, post_history_tags: [:tag])
                          .order(created_at: :desc, id: :desc).paginate(per_page: 20, page: params[:page])
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
               "(#{post_history_url(@post, anchor: index)})"
    }

    # If we are closing a question, also record the close reason from the original history item
    rollback_type = @history.post_history_type.name_inverted
    if rollback_type == 'question_closed'
      opts[:close_reason_id] = @history.close_reason_id
      opts[:duplicate_post_id] = @history.duplicate_post_id
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
      @history.reverted_with_id = new_history.id
      @history.save!
    end

    flash[:success] = 'History successfully rolled back'
    redirect_to post_history_path(@post)
  end

  def revert_to
    @post = Post.find(params[:post_id])
    @history = PostHistory.find(params[:id])

    msg = disallowed_to_restore(@post, @history, current_user)
    if msg.present?
      flash[:danger] = "You are not allowed to revert to this history element: #{msg}"
      redirect_to post_history_url(@post)
      return
    end

    revert_to_state(@post, @history)
  end

  protected

  # Reverts the given post to the state of the given history item by using the aggregated changes from to_change
  # @param post [Post]
  # @param history [PostHistory]
  def revert_to_state(post, history)
    to_change = determine_changes_to_restore(post, history)
    revert_comment = "Reverting to [##{index}: #{history.post_history_type.name.humanize}]" \
                     "(#{post_history_url(post, anchor: index)})"

    # Perform edit
    if to_change[:title].present? || to_change[:body].present? || to_change[:tags].present?
      opts = {
        before: post.body_markdown, before_title: post.title, before_tags: post.tags.to_a,
        comment: revert_comment
      }

      post.title = to_change[:title] if to_change[:title].present?
      if to_change[:body].present?
        post.body_markdown = to_change[:body]
        post.body = ApplicationController.helpers.render_markdown(to_change[:body])
      end
      post.tags_cache = to_change[:tags].map(&:name) if to_change[:tags].present?
      post.last_activity = DateTime.now
      post.last_activity_by = current_user
      post.save

      opts = opts.merge(after: post.body_markdown, after_title: post.title, after_tags: post.tags.to_a)

      PostHistory.post_edited(post, current_user, **opts)
    end

    # Perform close/reopen
    unless to_change[:closed].nil?
      if to_change[:closed]
        post.update(closed: true, closed_by: current_user, closed_at: DateTime.now,
                    close_reason_id: to_change[:close_reason_id],
                    duplicate_post_id: to_change[:duplicate_post_id],
                    last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.question_closed(post, current_user, comment: revert_comment,
                                    close_reason_id: to_change[:close_reason_id],
                                    duplicate_post_id: to_change[:duplicate_post_id])
      else
        post.update(closed: false, closed_by: nil, closed_at: nil, close_reason: nil, duplicate_post: nil,
                    last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.question_reopened(post, current_user, comment: revert_comment)
      end
    end

    # Perform deletion / undeletion
    unless to_change[:deleted].nil?
      if to_change[:deleted]
        post.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                    last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.post_deleted(post, current_user, comment: revert_comment)
      else
        post.update(deleted: false, deleted_at: nil, deleted_by: nil,
                    last_activity: DateTime.now, last_activity_by: current_user)
        PostHistory.post_undeleted(post, current_user, comment: revert_comment)
      end
    end
  end

  # This check is based on checking whether the user would be allowed to undo each of the history items that came after
  # the given one.
  #
  # @param post [Post]
  # @param history [PostHistory]
  # @param user [User]
  # @return [String, Nil] if the user is not allowed to restore, the message why not. Nil if the user is allowed to.
  def disallowed_to_restore(post, history, user)
    after_histories = post.post_histories
                          .where(created_at: history.created_at..)
                          .where.not(id: history.id)
                          .includes(:post_history_type)
                          .order(created_at: :desc, id: :desc)

    after_histories.each do |ph|
      msg = helpers.disallow_rollback_history(ph, user)
      return msg if msg

      if ['imported_from_external_source', 'initial_revision'].include?(ph.post_history_type.name)
        return "Events of the type #{ph.post_history_type.name.humanize} cannot be rolled back"
      end
    end

    nil
  end

  # Determines the set of changes to apply to the post to revert back to the state it had at the given history item.
  #
  # The returned hash can contain:
  #   deleted [Boolean] - whether the post should now be deleted
  #   closed [Boolean] - whether the post should be closed
  #   title [String] - the title the post should be updated to have
  #   body [String] - the body the post should be updated to have
  #   tags [Array<Tag>] - the tags the post should be updated to have
  #   close_reason_id [Integer] - the close reason that should be set
  #   duplicate_post_id [Integer] - the id of the post of which this post is a duplicate that should be set
  #
  # @param post [Post]
  # @param history [PostHistory]
  # @return [Hash]
  def determine_changes_to_restore(post, history)
    after_histories = post.post_histories
                          .where(created_at: history.created_at..)
                          .where.not(id: history.id)
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
      when 'imported_from_external_source', 'initial_revision'
        raise ArgumentError('Unexpected event in history revert request!')
      end
    end

    # Recover post close reason from predecessor of last reopened
    if to_change[:closed]
      ph = find_predecessor('question_closed', after_histories.last)
      to_change[:close_reason_id] = ph&.close_reason_id
      to_change[:duplicate_post_id] = ph&.duplicate_post_id
    end
    to_change
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
                   close_reason_id: predecessor.close_reason_id,
                   duplicate_post_id: predecessor.duplicate_post_id,
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
    when 'history_hidden'
      # We need to reveal history for all events that were hidden by this action
      histories_to_reveal = @post.post_histories
                                 .where(created_at: ..@history.created_at)
                                 .where(hidden: true)
                                 .includes(:post_history_type)
                                 .order(created_at: :desc, id: :desc)

      # If there are more history hiding events, only hide until the previous one.
      # We need to add one second because we don't want to reveal the edit before the history_hidden event, which
      # will have occurred in the same second.
      predecessor = find_predecessor('history_hidden', @history)
      histories_to_reveal = histories_to_reveal.where(created_at: (predecessor.created_at + 1.second)..) if predecessor

      histories_to_reveal.update_all(hidden: false)
    else
      false
    end
  end

  # @param type [String] the name of the history type
  # @param history [PostHistory]
  # @return [PostHistory, Nil] the history item of the given type that came before the given history item
  def find_predecessor(type, history)
    history.post.post_histories
           .where(post_history_type: PostHistoryType.find_by(name: type).id)
           .where(created_at: ..history.created_at)
           .where.not(id: history.id)
           .order(created_at: :desc, id: :desc)
           .first
  end
end
