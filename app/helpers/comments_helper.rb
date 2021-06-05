module CommentsHelper
  def comment_link(comment)
    if comment.post.parent_id.present?
      post_url(comment.post.parent_id, anchor: "comment-#{comment.id}")
    else
      post_url(comment.post, anchor: "comment-#{comment.id}")
    end
  end
end

class CommentScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a b i em strong strike del code]
    self.attributes = %w[href title]
  end

  def skip_node?(node)
    node.text?
  end
end
