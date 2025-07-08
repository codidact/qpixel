module CommentsControllerTestHelpers
  extend ActiveSupport::Concern

  private

  # Attempts to archive a given comment thread
  # @param thread [CommentThread] thread to archive
  def try_archive_thread(thread)
    post :thread_restrict, params: { id: thread.id, type: 'archive' }
  end

  # Attempts to create a comment thread on a given post
  # @param post [Post] post to create the thread on
  # @param mentions [Array<User>] list of user @-mentions, if any
  # @param content [String] content of the initial thread comment
  # @param title [String] title of the thread, if any
  def try_create_thread(post,
                        mentions: [],
                        content: 'sample comment content',
                        title: 'sample thread title',
                        format: :html)
    body_parts = [content] + mentions.map { |u| "@##{u.id}" }

    post(:create_thread, params: { post_id: post.id,
                                   title: title,
                                   body: body_parts.join(' ') },
                                   format: format)
  end

  # Attempts to create a comment in a given thread
  # @param thread [CommentThread] thread to create the comment in
  # @param mentions [Array<User>] list of user @-mentions, if any
  # @param content [String] content of the comment, if any
  # @param format [Symbol] whether to respond with HTML or JSON
  # @param inline [Boolean] whether to stay on the post page
  def try_create_comment(thread,
                         mentions: [],
                         content: 'sample comment content',
                         format: :html,
                         inline: false)
    content_parts = [content] + mentions.map { |u| "@##{u.id}" }

    post(:create, params: { id: thread.id,
                            post_id: thread.post.id,
                            content: content_parts.join(' '),
                            inline: inline },
                            format: format)
  end

  # Attempts to delete a given comment thread
  # @param thread [CommentThread] thread to delete
  def try_delete_thread(thread)
    post :thread_restrict, params: { id: thread.id, type: 'delete' }
  end

  # Attempts to undelete a given comment thread
  # @param thread [CommentThread] thread to undelete
  def try_undelete_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'delete' }
  end

  # Attempts to follow a given comment thread
  # @param thread [CommentThread] thread to follow
  def try_follow_thread(thread)
    post :thread_restrict, params: { id: thread.id, type: 'follow' }
  end

  # Attempts to unfollow a given comment thread
  # @param thread [CommentThread] thread to unfollow
  def try_unfollow_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'follow' }
  end

  # Attempts to lock a given comment thread
  # @param thread [CommentThread] thread to lock
  # @param duration [Integer] lock duration, in days
  def try_lock_thread(thread, duration: nil)
    post :thread_restrict, params: { duration: duration, id: thread.id, type: 'lock' }
  end

  # Attempts to unlock a given comment thread
  # @param thread [CommentThread] thread to unlock
  def try_unlock_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'lock' }
  end

  # Attempts to rename a given comment thread
  # @param thread [CommentThread] thread to rename
  # @param title [String] new thread title, if any
  def try_rename_thread(thread, title: 'new thread title')
    post :thread_rename, params: { id: thread.id, title: title }
  end

  # Attempts to show a single comment
  # @param comment [Comment] comment to show
  def try_show_comment(comment, format: :html)
    get :show, params: { id: comment.id, format: format }
  end

  # Attempts to show a single comment thread
  # @param thread [CommentThread] comment thread to show
  def try_show_thread(thread, format: :html)
    get :thread, params: { id: thread.id, format: format }
  end

  # Attempts to undelete a single comment
  # @param comment [Comment] comment to undelete
  def try_undelete_comment(comment, format: :html)
    patch :undelete, params: { id: comment.id, format: format }
  end

  # Attempts to update a given comment
  # @param comment [Comment] comment to update
  # @param content [String] new content of the comment, if any
  def try_update_comment(comment, content: 'Edited comment content')
    post :update, params: { id: comment.id, comment: { content: content } }
  end
end
