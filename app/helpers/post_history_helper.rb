module PostHistoryHelper
  def allow_rollback?(history, user)
    !disallow_rollback(history, user)
  end

  # @param history [PostHistory]
  # @param user [User]
  # @return [String] the error message if disallowed, or nil if allowed
  def disallow_rollback(history, user)
    # Invert the post name such that whatever is written for the when cases is the action we are trying to perform with
    # the rollback.
    case history.post_history_type.name_inverted
    when 'post_deleted'
      if !check_your_privilege('flag_curate') && !check_your_post_privilege(history.post, 'flag_curate')
        return ability_err_msg(:flag_curate, 'delete this post')
      end

      if history.post.children.any? { |a| !a.deleted? && a.score >= 0.5 } && !user.is_moderator
        i18ns('posts.cant_delete_responded')
      end
    when 'post_undeleted'
      if !check_your_privilege('flag_curate') && !check_your_post_privilege(history.post, 'flag_curate')
        ability_err_msg(:flag_curate, 'restore this post')
      end

      # Note, the history is for a post deletion, so the user linked to the history is the deleter.
      if history.user.is_moderator && !user.is_moderator
        i18ns('posts.cant_restore_deleted_by_moderator')
      end
    when 'question_closed'
      unless check_your_privilege('flag_close') || history.post.user_id == user.id
        ability_err_msg(:flag_close, 'close this post')
      end
    when 'question_reopened'
      if !check_your_privilege('flag_close') || @post.user.id == user.id
        ability_err_msg(:flag_close, 'reopen this post')
      end
    when 'post_edited'
      if !user.privilege?('edit_posts') && !user.is_moderator && user != history.post.user && \
         (!history.post.post_type.is_freely_editable || !user.privilege?('unrestricted'))
        ability_err_msg(:edit_posts, 'edit this post')
      end
    end
  end
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
