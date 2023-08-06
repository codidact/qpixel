module PostHistoryHelper
  # @param closed [Boolean] whether this post will be closed (true) or reopened (false)
  # @param close_reason [CloseReason, Nil] the close reason for this post (if present)
  # @param duplicate_post [Post, Nil] the post which is linked as duplicate (if present)
  def close_description(closed, close_reason, duplicate_post)
    base = ''.html_safe
    if closed && close_reason
      base += " as #{close_reason.name}"
      if duplicate_post
        base += " of <a href=\"#{post_url(duplicate_post)}\" target=\"_blank\">".html_safe
        base += "##{duplicate_post.id} (#{duplicate_post.title})"
        base += '</a>'.html_safe
      end
    end
    base
  end

  # @param history [PostHistory]
  # @param user [User, Nil]
  # @return [Boolean] whether the given user is allowed to roll back to the given history item
  def allow_roll_back_to_history?(history, user)
    user.present? && !disallow_roll_back_to_history(history, user)
  end

  def disallow_roll_back_to_history(history, user)
    # TODO
  end

  # @param history [PostHistory]
  # @param user [User, Nil]
  # @return [Boolean] whether the given user is allowed to undo the given history item
  def allow_undo_history?(history, user)
    user.present? && !disallow_undo_history(history, user)
  end

  # @param history [PostHistory]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_undo_history(history, user)
    if history.hidden? && history.user_id != user.id && !user.is_admin
      return i18ns('post_histories.cant_undo_hidden')
    end

    case history.post_history_type.name
    when 'post_undeleted'
      disallow_delete(history.post, user)
    when 'post_deleted'
      disallow_undelete(history.post, user)
    when 'question_reopened'
      disallow_close(history.post, user)
    when 'question_closed'
      disallow_reopen(history.post, user)
    when 'post_edited'
      disallow_edit(history.post, user)
    when 'history_hidden'
      disallow_reveal_history(history, user)
    when 'history_revealed'
      disallow_hide_history(history, user)
    else
      'Unsupported history type'
    end
  end

  # @param post [Post]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_delete(post, user)
    if !user.privilege?('flag_curate') && !user.has_post_privilege?('flag_curate', post)
      return ability_err_msg(:flag_curate, 'delete this post')
    end

    if post.children.any? { |a| !a.deleted? && a.score >= 0.5 } && !user.is_moderator
      i18ns('posts.cant_delete_responded')
    end
  end

  # @param post [Post]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_undelete(post, user)
    if !user.privilege?('flag_curate') && !user.has_post_privilege?('flag_curate', post)
      ability_err_msg(:flag_curate, 'restore this post')
    end

    # It could be the case that the post is already no longer deleted, which is why we need the safety &.
    if post.deleted_by&.is_moderator && !user.is_moderator
      i18ns('posts.cant_restore_deleted_by_moderator')
    end
  end

  # @param post [Post]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_close(post, user)
    unless check_your_privilege('flag_close') || post.user_id == user.id
      ability_err_msg(:flag_close, 'close this post')
    end
  end

  # @param post [Post]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_reopen(post, user)
    if !user.privilege?('flag_close') || post.user_id == user.id
      ability_err_msg(:flag_close, 'reopen this post')
    end
  end

  # @param post [Post]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_edit(post, user)
    if !user.privilege?('edit_posts') && !user.is_moderator && user.id != post.user_id && \
       (!post.post_type.is_freely_editable || !user.privilege?('unrestricted'))
      ability_err_msg(:edit_posts, 'edit this post')
    end
  end

  # @param history [PostHistory]
  # @param user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_reveal_history(history, user)
    unless user.is_admin || history.user_id == user.id
      i18ns('post_histories.cant_reveal')
    end
  end

  # @param _history [PostHistory]
  # @param _user [User]
  # @return [String, Nil] the error message if disallowed, or nil if allowed
  def disallow_hide_history(_history, _user); end
end

class PostHistoryScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a b i em strong s strike del sup sub]
    self.attributes = %w[href title lang dir id class start]
  end

  def skip_node?(node)
    node.text?
  end
end
