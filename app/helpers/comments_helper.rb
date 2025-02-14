module CommentsHelper
  def comment_link(comment)
    if comment.deleted
      comment_thread_url(comment.comment_thread_id, show_deleted_comments: 1, anchor: "comment-#{comment.id}",
                         host: comment.community.host)
    else
      comment_thread_url(comment.comment_thread_id, anchor: "comment-#{comment.id}", host: comment.community.host)
    end
  end

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
end

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
