module PostActions
  extend ActiveSupport::Concern

  # Updates the given post with the given params and creates the corresponding events.
  #
  # @param post [Post]
  # @param user [User]
  # @param params [Hash]
  # @param body_rendered [String, Nil]
  # @param comment [String, Nil]
  # @return [PostHistory, False] if the update succeeded, the history event, false otherwise
  def update_post(post, user, params, body_rendered, comment: nil)
    before = { body: @post.body_markdown, title: @post.title, tags: @post.tags.to_a }

    params[:body] = body_rendered if body_rendered
    params = params.merge(last_edited_at: DateTime.now, last_edited_by: user,
                          last_activity: DateTime.now, last_activity_by: user)

    if post.update(params)
      PostHistory.post_edited(post, user, comment: comment,
                              before: before[:body], after: post.body_markdown,
                              before_title: before[:title], after_title: post.title,
                              before_tags: before[:tags], after_tags: post.tags)
    else
      false
    end
  end

  # Whether the given user is allowed to directly edit the given post.
  #
  # @param user [User]
  # @param post [Post]
  # @param post_type [PostType]
  def can_update_post?(user, post, post_type)
    user.privilege?('edit_posts') || user.is_moderator || user == post.user ||
      (post_type.is_freely_editable && user.privilege?('unrestricted'))
  end
end
