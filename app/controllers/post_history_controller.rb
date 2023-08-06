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

  def undo
    @history = PostHistory.find(params[:id])
    @post = @history.post
    histories = @post.post_histories.order(created_at: :asc).ids
    index = histories.index(@history.id) + 1

    unless @history.can_undo?
      flash[:danger] = 'You cannot undo this particular history element.'
      redirect_to post_history_url(@post)
      return
    end

    msg = helpers.disallow_undo_history(@history, current_user)
    if msg.present?
      flash[:danger] = "You are not allowed to undo this history element: #{msg}"
      redirect_to post_history_url(@post)
      return
    end

    opts = {
      before: @post.body_markdown, before_title: @post.title, before_tags: @post.tags.to_a,
      comment: "Undo of [##{index}: #{@history.post_history_type.name.humanize}]" \
               "(#{post_history_url(@post, anchor: index)})"
    }

    # If we are closing a question, also record the close reason from the original history item
    undo_type = @history.post_history_type.name_inverted
    if undo_type == 'question_closed'
      predecessor = @history.find_predecessor('question_closed')
      opts[:close_reason_id] = predecessor&.close_reason_id
      opts[:duplicate_post_id] = predecessor&.duplicate_post_id
    end

    PostHistory.transaction do
      unless undo_post_history(@history)
        flash[:danger] = "Unable to undo revision: #{@post.errors.full_messages.join(', ')}"
        redirect_to post_history_path(@post)
        return
      end

      opts = opts.merge(after: @post.body_markdown, after_title: @post.title, after_tags: @post.tags.to_a)

      # Record in the history that this element was rolled back
      new_history = PostHistory.send(undo_type, @post, current_user, **opts)

      # Set the original to be rolled back
      @history.reverted_with_id = new_history.id
      @history.save!
    end

    flash[:success] = 'History successfully rolled back'
    redirect_to post_history_path(@post)
  end

  def revert_overview
    @history = PostHistory.find(params[:id])
    @post = @history.post

    @changes = determine_changes_to_restore(@post, @history)

    # Check whether we would actually be making changes
    if @changes.empty?
      flash[:warning] = 'You cannot revert to this history element: no changes would be made.'
      redirect_to post_history_url(@post)
      return
    end

    # Check permission for making these changes
    msg = disallowed_to_restore(@changes, @post, current_user)
    if msg.present?
      flash[:danger] = "You are not allowed to revert to this history element: #{msg}"
      redirect_to post_history_url(@post)
      return
    end

    @full_history = @post.post_histories
                         .includes(:post_history_type, :user, post_history_tags: [:tag])
                         .order(created_at: :desc, id: :desc)
    # We use map id here over .ids to reuse the cached database result from this method getting called earlier
    # (in determine_changes_to_restore)
    @undo_history_ids = determine_events_to_undo(@post, @history).map(&:id)

    render layout: 'without_sidebar'
  end

  def revert_to
    @history = PostHistory.find(params[:id])
    @post = @history.post

    comment = params[:edit_comment]
    if comment.blank?
      flash[:danger] = 'You need to provide a comment for why you are making this revertion'
      redirect_to revert_overview_post_history_path(@post, @history)
      return
    end

    # Determine the changes that we need to make
    to_change = determine_changes_to_restore(@post, @history)

    if to_change.empty?
      flash[:warning] = 'You cannot revert to this history element: no changes would be made.'
      redirect_to post_history_url(@post)
      return
    end

    # Check whether the user is allowed to make those changes
    msg = disallowed_to_restore(to_change, @post, current_user)
    unless msg.nil?
      flash[:danger] = "You are not allowed to revert to this history element: #{msg}"
      redirect_to post_history_url(@post)
      return
    end

    # Actually apply the changes
    Post.transaction do
      revert_to_state(to_change, @post, @history, comment)
    end

    flash[:success] = 'Successfully rolled back.'
    redirect_to post_history_url(@post)
  end

  protected

  # Reverts the given post to the state of the given history item by using the aggregated changes from to_change
  # @param to_change [Hash] the changes to make, output of `determine_changes_to_restore`
  # @param post [Post]
  # @param history [PostHistory]
  def revert_to_state(to_change, post, history, comment)
    index = post.post_histories.order(created_at: :desc, id: :desc).ids.index(history.id)
    revert_comment = "Reverting to [##{index}: #{history.post_history_type.name.humanize}]" \
                     "(#{post_history_url(post, anchor: index)}): #{comment}"

    edit_event = nil
    close_event = nil
    delete_event = nil

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
      edit_event = PostHistory.post_edited(post, current_user, **opts)
    end

    # Perform close/reopen
    unless to_change[:closed].nil?
      if to_change[:closed]
        post.update(closed: true, closed_by: current_user, closed_at: DateTime.now,
                    close_reason_id: to_change[:close_reason],
                    duplicate_post_id: to_change[:duplicate_post],
                    last_activity: DateTime.now, last_activity_by: current_user)
        close_event = PostHistory.question_closed(post, current_user, comment: revert_comment,
                                                  close_reason_id: to_change[:close_reason],
                                                  duplicate_post_id: to_change[:duplicate_post])
      else
        undo_post_close(post)
        close_event = PostHistory.question_reopened(post, current_user, comment: revert_comment)
      end
    end

    # Perform deletion / undeletion
    unless to_change[:deleted].nil?
      if to_change[:deleted]
        post.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                    last_activity: DateTime.now, last_activity_by: current_user)
        delete_event = PostHistory.post_deleted(post, current_user, comment: revert_comment)
      else
        undo_post_delete(post)
        delete_event = PostHistory.post_undeleted(post, current_user, comment: revert_comment)
      end
    end

    revert_history_items(history, edit_event, close_event, delete_event)
  end

  # Updates the post histories by setting by which event they were reverted.
  # @param history [PostHistory]
  # @param edit_event [PostHistory, Nil]
  # @param close_event [PostHistory, Nil]
  # @param delete_event [PostHistory, Nil]
  def revert_history_items(history, edit_event, close_event, delete_event)
    events_to_undo = determine_events_to_undo(history.post, history)
    events_to_undo.each do |ph|
      case ph.post_history_type.name
      when 'post_deleted', 'post_undeleted'
        ph.update(reverted_with_id: delete_event)
      when 'question_closed', 'question_reopened'
        ph.update(reverted_with_id: close_event)
      when 'post_edited'
        ph.update(reverted_with_id: edit_event)
      end
    end
  end

  # This check is based on checking whether the user would be allowed to undo each of the history items that came after
  # the given one.
  #
  # @param to_change [Hash] output of `determine_changes_to_restore`
  # @param post [Post]
  # @param user [User]
  # @return [String, Nil] if the user is not allowed to restore, the message why not. Nil if the user is allowed to.
  def disallowed_to_restore(to_change, post, user)
    if to_change.include?(:deleted)
      msg = if to_change[:deleted]
              helpers.disallow_delete(post, user)
            else
              helpers.disallow_undelete(post, user)
            end
      return msg if msg
    end

    if to_change.include?(:closed)
      msg = if to_change[:closed]
              helpers.disallow_close(post, user)
            else
              helpers.disallow_reopen(post, user)
            end
      return msg if msg
    end

    if to_change[:title] || to_change[:body] || to_change[:tags]
      msg = helpers.disallow_edit(post, user)
      return msg if msg
    end

    nil
  end

  # Determines the events to undo to revert to the given history item.
  # Events are ordered in the order in which they need to be undone (newest to oldest).
  #
  # @param post [Post]
  # @param history [PostHistory] the history item to revert the state to
  def determine_events_to_undo(post, history)
    revertable_types = %w[post_edited post_deleted post_undeleted question_closed question_reopened]
    post.post_histories
        .where(created_at: (history.created_at + 1.second)..)
        .where(post_history_type: PostHistoryType.where(name: revertable_types))
        .includes(:post_history_type)
        .order(created_at: :desc, id: :desc)
  end

  # Determines the set of changes to apply to the post to revert back to the state it had at the given history item.
  #
  # The returned hash can contain:
  #   deleted [Boolean] - whether the post should now be deleted
  #   closed [Boolean] - whether the post should be closed
  #   title [String] - the title the post should be updated to have
  #   body [String] - the body the post should be updated to have
  #   tags [Array<Tag>] - the tags the post should be updated to have
  #   close_reason [CloseReason] - the close reason that should be set
  #   duplicate_post [Post] - the post of which this post is a duplicate that should be set
  #
  # @param post [Post]
  # @param history [PostHistory]
  # @return [Hash]
  def determine_changes_to_restore(post, history)
    events_to_undo = determine_events_to_undo(post, history)

    # Aggregate changes from events
    to_change = {}
    events_to_undo.each do |ph|
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
      ph = events_to_undo.last.find_predecessor('question_closed')
      to_change[:close_reason] = ph&.close_reason
      to_change[:duplicate_post] = ph&.duplicate_post
    end

    # Cleanup changes that are already present
    to_change.delete(:title) if to_change[:title] == post.title
    to_change.delete(:body) if to_change[:body] == post.body_markdown
    to_change.delete(:tags) if to_change[:tags]&.map(&:id)&.sort == post.tags.ids.sort
    to_change.delete(:deleted) if to_change[:deleted] == post.deleted

    if to_change[:closed] == post.closed &&
       to_change[:close_reason] == post.close_reason &&
       to_change[:duplicate_post]&.id == post.duplicate_post_id
      to_change.delete(:closed)
    end

    to_change
  end

  private

  # Undoes the given history item.
  # @param history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_history(history)
    post = history.post
    case history.post_history_type.name
    when 'post_deleted'
      undo_post_delete(post)
    when 'post_undeleted'
      undo_post_undelete(post, history)
    when 'question_closed'
      undo_post_close(post)
    when 'question_reopened'
      undo_post_reopen(post, history)
    when 'post_edited'
      undo_post_edit(post, history)
    when 'history_hidden'
      undo_hide_history(post, history)
    when 'history_revealed'
      undo_reveal_history(post, history)
    else
      false
    end
  end

  # @param post [Post]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_delete(post)
    post.update(deleted: false, deleted_at: nil, deleted_by: nil,
                last_activity: DateTime.now, last_activity_by: current_user)
  end

  # @param post [Post]
  # @param _history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_undelete(post, _history)
    # predecessor = history.find_predecessor('post_deleted')
    post.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                last_activity: DateTime.now, last_activity_by: current_user)
  end

  # @param post [Post]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_close(post)
    post.update(closed: false, closed_by: nil, closed_at: nil, close_reason: nil, duplicate_post: nil,
                last_activity: DateTime.now, last_activity_by: current_user)
  end

  # @param post [Post]
  # @param history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_reopen(post, history)
    predecessor = history.find_predecessor('question_closed')

    post.update(closed: true, closed_by: current_user, closed_at: DateTime.now,
                close_reason_id: predecessor.close_reason_id,
                duplicate_post_id: predecessor.duplicate_post_id,
                last_activity: DateTime.now, last_activity_by: current_user)
  end

  # @param post [Post]
  # @param history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_edit(post, history)
    post.title = history.before_title if history.before_title && history.before_title != history.after_title
    if history.before_state && history.before_state != history.after_state
      post.body_markdown = history.before_state
      post.body = ApplicationController.helpers.render_markdown(history.before_state)
    end
    post.tags_cache += history.tags_removed.map(&:name)
    post.tags_cache -= history.tags_added.map(&:name)
    post.last_activity = DateTime.now
    post.last_activity_by = current_user
    post.save
  end

  # @param post [Post]
  # @param history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_hide_history(post, history)
    # We need to reveal history for all events that were hidden by this action
    histories_to_reveal = post.post_histories
                              .where(created_at: ..history.created_at)
                              .where(hidden: true)
                              .includes(:post_history_type)
                              .order(created_at: :desc, id: :desc)

    # If there are more history hiding events, only hide until the previous one.
    # We need to add one second because we don't want to reveal the edit before the history_hidden event, which
    # will have likely occurred in the same second.
    # Note that we do want to include the history_hidden item itself, so we add that with or.
    predecessor = history.find_predecessor('history_hidden')
    if predecessor
      histories_to_reveal = histories_to_reveal.where(created_at: (predecessor.created_at + 1.second)..)
                                               .or(PostHistory.where(id: predecessor))
    end

    histories_to_reveal.update_all(hidden: false, updated_at: DateTime.now).positive?
  end

  # @param post [Post]
  # @param history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_reveal_history(post, history)
    # We need to hide history for all events that were revealed by this action
    histories_to_hide = post.post_histories
                            .where(created_at: ..history.created_at)
                            .where(hidden: true)
                            .includes(:post_history_type)
                            .order(created_at: :desc, id: :desc)

    # If there are more history hiding events, only reveal until the previous previous hiding.
    # That is, we revealed hiding 1, now we are hiding again (confusing I know).
    # We need to add one second because we don't want to hide the edit before the history_hidden event, which
    # will have likely occurred in the same second.
    # Note that we do want to include the history_hidden item itself, so we add that with or.
    predecessor = history.find_predecessor('history_hidden')&.find_predecessor('history_hidden')
    if predecessor
      histories_to_hide = histories_to_hide.where(created_at: (predecessor.created_at + 1.second)..)
                                               .or(PostHistory.where(id: predecessor))
    end

    histories_to_hide.update_all(hidden: true, updated_at: DateTime.now).positive?
  end
end
