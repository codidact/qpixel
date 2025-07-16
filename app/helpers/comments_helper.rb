# Helpers related to comments.
module CommentsHelper
  # Generates a comment thread title from its body
  # @param body [String] coment thread body
  # @return [String] generated title
  def generate_thread_title(body)
    body = strip_markdown(body)
    body = body.gsub(/^>.+?$/, '') # also remove leading blockquotes

    if body.length > 100
      "#{body[0..100]}..."
    else
      body
    end
  end

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

  # Gets a link to a given comment's user
  # @param comment [Comment] comment to link the user for
  # @return [String] comment user link
  def comment_user_link(comment)
    user_link(comment.user, { host: comment.community.host })
  end

  # Extracts user ID from a given ping string (i.e. @#1234)
  # @param ping [String] ping to extract from
  # @return [Integer] extracted ID
  def uid_from_ping(ping)
    ping[2..-1].to_i
  end

  ##
  # Process a comment and convert ping-strings (i.e. @#1234) into links.
  # @param comment [String] The text of the comment to process.
  # @param pingable [Array<Integer>, nil] A list of user IDs that should be pingable in this comment. Any user IDs not
  #   present in the list will be displayed as 'unpingable'.
  # @return [ActiveSupport::SafeBuffer]
  def render_pings(comment, pingable: nil)
    comment.gsub(/@#\d+/) do |ping|
      user = User.where(id: uid_from_ping(ping)).first
      if user.nil?
        ping
      else
        was_pung = pingable.present? && pingable.include?(user.id)
        classes = "ping #{user.same_as?(current_user) ? 'me' : ''} #{was_pung ? '' : 'unpingable'}"
        user_link user, class: classes, dir: 'ltr',
                  title: was_pung ? '' : 'This user was not notified because they have not participated in this thread.'
      end
    end.html_safe
  end

  # Converts all ping strings (i.e. @#1234) in content into usernames for use in text-only contexts
  # @param content [String] content to convert ping strings for
  # @return [String] processed content
  def render_pings_text(content)
    content.gsub(/@#\d+/) do |ping|
      user = User.where(id: uid_from_ping(ping)).first
      "@#{user.nil? ? ping : rtl_safe_username(user)}"
    end
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
      I18n.t('comments.errors.disabled_on_locked_posts')
    elsif post.deleted?
      I18n.t('comments.errors.disabled_on_deleted_posts')
    elsif post.comments_disabled
      I18n.t('comments.errors.disabled_on_post_specific')
    else
      I18n.t('comments.errors.disabled_on_post_generic')
    end.strip
  end

  # Gets a standard comments error message for a given thread
  # @param thread [CommentThread] target thread
  # @return [String] error message
  def comments_thread_error_msg(thread)
    if thread.locked?
      I18n.t('comments.errors.disabled_on_locked_threads')
    elsif thread.deleted
      I18n.t('comments.errors.disabled_on_deleted_threads')
    elsif thread.archived
      I18n.t('comments.errors.disabled_on_archived_threads')
    else
      I18n.t('comments.errors.disabled_on_thread_generic')
    end.strip
  end

  # Gets a standard comments rate limit error message for a given user & post
  # @param user [User] user to get the comments count for
  # @param post [Post] post to get the comments count for
  def rate_limited_error_msg(user, post)
    comments_count = user.recent_comments_count(post)
    I18n.t('comments.errors.rate_limited', count: comments_count)
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

    unless is_rate_limited && user.standard?
      return [false, nil]
    end

    if user.new? && !user.owns_post_or_parent?(post) && comments_limit.zero?
      message = I18n.t('comments.errors.new_user_rate_limited')

      if create_audit_log
        AuditLog.rate_limit_log(event_type: 'comment', related: post, user: user,
                                comment: "'unrestricted' ability required to comment on non-owned posts")
      end
    else
      message = rate_limited_error_msg(user, post)

      if create_audit_log
        AuditLog.rate_limit_log(event_type: 'comment', related: post, user: user, comment: "limit: #{comments_limit}")
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
