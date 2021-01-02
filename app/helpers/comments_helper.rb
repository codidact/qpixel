module CommentsHelper
  def comment_link(comment)
    if comment.deleted
      comment_thread_path(comment.comment_thread_id) + "?show_deleted_comments=1#comment-#{comment.id}"
    else
      comment_thread_path(comment.comment_thread_id) + "#comment-#{comment.id}"
    end
  end

  def render_pings(comment)
    comment.gsub(/\[\[PING [0-9]+\]\]/) do |id|
      u = User.where(id: id[7...-2].to_i).first
      return id if u.nil?
      
      if u.id == current_user&.id
        "<a href=\"#{u.id}\" class=\"ping me\" dir=\"ltr\">@#{u.rtl_safe_username}</a>"
      else
        "<a href=\"#{u.id}\" class=\"ping\" dir=\"ltr\">@#{u.rtl_safe_username}</a>"
      end
    end.html_safe
  end

  def get_pingable(thread)
    post = thread.post
    
    pingable = {
      post.user.username => post.user_id,
      post.user.username + '#' + post.user_id.to_s => post.user_id,
      post.user_id => post.user_id,
    }

    post.post_histories.last(500).each do |h|
      pingable.merge!({
        h.user.username => h.user_id,
        h.user.username + '#' + h.user_id.to_s => h.user_id,
        h.user_id => h.user_id,
      })
    end

    thread.comments.last(500).each do |c|
      pingable.merge!({
        c.user.username => c.user_id,
        c.user.username + '#' + c.user_id.to_s => c.user_id,
        c.user_id => c.user_id,
      })
    end

    thread.thread_follower.each do |f|
      pingable.merge!({
        f.user.username => f.user_id,
        f.user.username + '#' + f.user_id.to_s => f.user_id,
        f.user_id => f.user_id,
      })
    end
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
