module CommentsHelper
  def comment_link(comment)
    if comment.deleted
      comment_thread_path(comment.comment_thread_id) + "?show_deleted_comments=1#comment-#{comment.id}"
    else
      comment_thread_path(comment.comment_thread_id) + "#comment-#{comment.id}"
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
