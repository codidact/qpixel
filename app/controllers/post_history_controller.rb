class PostHistoryController < ApplicationController
  include PostActions

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

  def rollback_overview
    @history = PostHistory.find(params[:id])
    @post = @history.post

    @changes = determine_changes_to_restore(@post, @history)

    # Check whether we would actually be making changes
    if @changes.empty?
      flash[:warning] = 'You cannot rollback to this history element: no changes would be made.'
      redirect_to post_history_url(@post)
      return
    end

    # Check whether the user is allowed to make those changes
    unless can_update_post?(current_user, @post, @post.post_type)
      flash[:danger] = ability_err_msg(:edit_posts, 'edit this post')
      redirect_to post_history_url(@post)
      return
    end

    @full_history = @post.post_histories
                         .includes(:post_history_type, :user, post_history_tags: [:tag])
                         .order(created_at: :desc, id: :desc)
    # We use map id here over .ids to reuse the cached database result from this method getting called earlier
    # (in determine_changes_to_restore)
    @undo_history_ids = determine_edit_events_to_undo(@post, @history).map(&:id)

    render layout: 'without_sidebar'
  end

  def rollback_to
    @history = PostHistory.find(params[:id])
    @post = @history.post

    comment = params[:edit_comment]
    if comment.blank?
      flash[:danger] = 'You need to provide a comment for why you are rolling back.'
      redirect_to rollback_overview_post_history_path(@post, @history)
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
    msg = helpers.disallow_roll_back_to_history(@history, current_user)
    if msg
      flash[:danger] = msg
      redirect_to post_history_url(@post)
      return
    end

    # Actually apply the changes
    revert_to_state(to_change, @post, @history, comment)

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

    change_params = {}
    change_params[:title] = to_change[:title] if to_change[:title].present?
    change_params[:tags_cache] = to_change[:tags].map(&:name) if to_change[:tags].present?

    body_rendered = nil
    if to_change[:body].present?
      change_params[:body_markdown] = to_change[:body]
      body_rendered = ApplicationController.helpers.render_markdown(to_change[:body])
    end

    edit_event = update_post(post, current_user, change_params, body_rendered, comment: revert_comment)

    revert_history_items(history, edit_event)
  end

  # Updates the post histories by setting by which event they were reverted.
  # @param history [PostHistory]
  # @param edit_event [PostHistory, Nil]
  def revert_history_items(history, edit_event)
    determine_edit_events_to_undo(history.post, history)
      .update_all(reverted_with_id: edit_event, edited_at: DateTime.now)
  end

  # Determines the edit events to undo to revert to the given history item.
  # Events are ordered in the order in which they need to be undone (newest to oldest).
  #
  # @param post [Post]
  # @param history [PostHistory] the history item to revert the state to
  def determine_edit_events_to_undo(post, history)
    post.post_histories
        .where(created_at: (history.created_at + 1.second)..)
        .where(post_history_type: PostHistoryType.where(name: 'post_edited'))
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
    events_to_undo = determine_edit_events_to_undo(post, history)

    # Aggregate changes from events
    to_change = {}
    events_to_undo.each do |ph|
      case ph.post_history_type.name
      when 'post_edited'
        to_change[:title] = ph.before_title if ph.before_title.present?
        to_change[:body] = ph.before_state if ph.before_state.present?
        to_change[:tags] = ph.before_tags if ph.before_tags.present?
      end
    end

    # Cleanup changes that are already present
    to_change.delete(:title) if to_change[:title] == post.title
    to_change.delete(:body) if to_change[:body] == post.body_markdown
    to_change.delete(:tags) if to_change[:tags]&.map(&:id)&.sort == post.tags.ids.sort

    to_change
  end

  private

  # Undoes the given history item.
  # @param history [PostHistory]
  # @return [Boolean] whether the undo was successfully applied
  def undo_post_history(history)
    post = history.post
    case history.post_history_type.name
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
