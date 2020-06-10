module CommentsHelper
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
