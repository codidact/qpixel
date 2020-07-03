module PostsHelper
  class PostScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w[a p b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li sup sub
                     section]
      self.attributes = %w[id class href title src height width alt]
    end

    def skip_node?(node)
      node.text?
    end
  end

  def scrubber
    PostsHelper::PostScrubber.new
  end
end
