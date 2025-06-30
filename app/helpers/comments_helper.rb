# Helpers related to comments.
module CommentsHelper
  ##
  # Get a link to the specified comment, accounting for deleted comments.
  # @param comment [Comment]
  # @return [String]
  def comment_link(comment)
    if comment.deleted
      comment_thread_url(comment.comment_thread_id, show_deleted_comments: 1, anchor: "comment-#{comment.id}",
                         host: comment.community.host)
    else
      comment_thread_url(comment.comment_thread_id, anchor: "comment-#{comment.id}", host: comment.community.host)
    end
  end

  ##
  # Process a comment and convert ping-strings (i.e. @#1234) into links.
  # @param comment [String] The text of the comment to process.
  # @param pingable [Array<Integer>, nil] A list of user IDs that should be pingable in this comment. Any user IDs not
  #   present in the list will be displayed as 'unpingable'.
  # @return [ActiveSupport::SafeBuffer]
  def render_pings(comment, pingable: nil)
    comment.gsub(/@#\d+/) do |id|
      u = User.where(id: id[2..-1].to_i).first
      if u.nil?
        id
      else
        was_pung = pingable.present? && pingable.include?(u.id)
        classes = "ping #{u.id == current_user&.id ? 'me' : ''} #{was_pung ? '' : 'unpingable'}"
        user_link u, class: classes, dir: 'ltr',
                  title: was_pung ? '' : 'This user was not notified because they have not participated in this thread.'
      end
    end.html_safe
  end

  ##
  # Process comment text and convert helper links (like [help] and [flags]) into real links.
  # @param comment_text [String] The text of the comment to process.
  # @param user [User] Specify a user whose pages to link to from user-related helpers.
  # @return [String]
  def render_comment_helpers(comment_text, user = current_user)
    comment_text.gsub!(/\[(help( center)?)\]/, "<a href=\"#{help_center_url}\">\\1</a>")

    unless user.nil?
      comment_text.gsub!(/\[(votes?)\]/, "<a href=\"#{my_vote_summary_url}\">\\1</a>")
      comment_text.gsub!(/\[(flags?)\]/, "<a href=\"#{flag_history_url(user)}\">\\1</a>")
    end

    comment_text.gsub!(/\[category:(.+?)\]/) do |match|
      val = Regexp.last_match(1).gsub('&amp;', '&').downcase
      cat = Category.by_lowercase_name(val)
      if cat
        "<a href=\"#{category_url(cat)}\">#{cat.name}</a>"
      else
        match
      end
    end

    comment_text.gsub!(/\[category\#([0-9]+)\]/) do |match|
      val = Regexp.last_match(1).to_i
      cat = Category.by_id(val)
      if cat
        "<a href=\"#{category_url(cat)}\">#{cat.name}</a>"
      else
        match
      end
    end

    comment_text
  end

  # Gets a standard comments error message for a given post
  # @param post [Post] target post
  # @return [String] error message
  def comments_post_error_msg(post)
    if post.locked?
      'Comments are disabled on locked posts.'
    elsif post.deleted?
      'Comments are disabled on deleted posts.'
    elsif post.comments_disabled
      'Comments on this post are disabled.'
    else
      'This post cannot be commented on.' # just in case
    end
  end

  # Gets a standard comments error message for a given thread
  # @param thread [CommentThread] target thread
  # @return [String] error message
  def comments_thread_error_msg(thread)
    if thread.locked?
      'Locked threads cannot be replied to.'
    elsif thread.deleted
      'Deleted threads cannot be replied to.'
    elsif thread.archived
      'Archived threads cannot be replied to.'
    else
      'This thread cannot be replied to.' # just in case
    end
  end

  ##
  # Get a list of user IDs who should be pingable in a specified comment thread. This combines the post author, answer
  # authors, recent history event authors, recent comment authors on the post (in any thread), and all thread followers.
  # @param thread [CommentThread]
  # @return [Array<Integer>]
  def get_pingable(thread)
    post = thread.post

    # post author +
    # answer authors +
    # last 500 history event users +
    # last 500 comment authors +
    # all thread followers
    query = <<~END_SQL
      SELECT posts.user_id FROM posts WHERE posts.id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT posts.user_id FROM posts WHERE posts.parent_id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT ph.user_id FROM post_histories ph WHERE ph.post_id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT comments.user_id FROM comments WHERE comments.post_id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT tf.user_id FROM thread_followers tf WHERE tf.comment_thread_id = #{thread.id || '-1'}
    END_SQL

    ActiveRecord::Base.connection.execute(query).to_a.flatten
  end

  ##
  # Is the specified user comment rate limited for the specified post?
  # @param user [User] The user to check.
  # @param post [Post] The post on which the user proposes to comment.
  # @param create_audit_log [Boolean] Whether to create an AuditLog if the user is rate limited.
  # @return [Array(Boolean, String)] 2-tuple: boolean indicating if the user is rate-limited, and a string containing
  #   a rate limit message if the user is rate-limited.
  def comment_rate_limited?(user, post, create_audit_log: true)
    comments_count = user.recent_comments_count(post)
    comments_limit = user.max_comments_per_day(post)
    is_rate_limited = comments_count >= comments_limit

    unless is_rate_limited
      return [false, nil]
    end

    if user.new? && !user.owns_post_or_parent?(post) && comments_limit.zero?
      message = 'As a new user, you can only comment on your own posts and on answers to them.'

      if create_audit_log
        AuditLog.rate_limit_log(event_type: 'comment', related: post, user: user,
                                comment: "'unrestricted' ability required to comment on non-owned posts")
      end
    else
      message = "You have used your daily limit of #{comments_count} comments. Come back tomorrow to continue."

      if create_audit_log
        AuditLog.rate_limit_log(event_type: 'comment', related: post, user: user,
                                comment: "limit: #{comments_limit}")
      end
    end

    [true, message]
  end
end

# HTML sanitizer for use with comments.
class CommentScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a b i em strong s strike del pre code p blockquote span sup sub br ul ol li]
    self.attributes = %w[href title lang dir id class start]
  end

  def skip_node?(node)
    node.text?
  end
end
