module CommentsHelper
  def comment_link(comment)
    if comment.deleted
      comment_thread_path(comment.comment_thread_id) + "?show_deleted_comments=1#comment-#{comment.id}"
    else
      comment_thread_path(comment.comment_thread_id) + "#comment-#{comment.id}"
    end
  end

  def render_pings(comment)
    comment.gsub(/@#\d+/) do |id|
      u = User.where(id: id[2..-1].to_i).first
      if u.nil?
        id
      else
        safe_username = sanitize(u.rtl_safe_username.gsub('<', '&#x3C;').gsub('>', '&#x3E;'))
        if u.id == current_user&.id
          "<a href=\"#{user_path(u.id)}\" class=\"ping me\" dir=\"ltr\">@#{safe_username}</a>"
        else
          "<a href=\"#{user_path(u.id)}\" class=\"ping\" dir=\"ltr\">@#{safe_username}</a>"
        end
      end
    end.html_safe
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
    self.tags = %w[a b i em strong strike del code p]
    self.attributes = %w[href title]
  end

  def skip_node?(node)
    node.text?
  end
end
