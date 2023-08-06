module PostHistoryHelper
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
