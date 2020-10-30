module PostsHelper
  def post_markdown(scope, field_name)
    if params['__html'].present?
      params['__html']
    else
      render_markdown(params[scope][field_name])
    end
  end

  class PostScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w[a p b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li sup sub
                     section details summary ins table thead tbody tr th td]
      self.attributes = %w[id class href title src height width alt rowspan colspan]
    end

    def skip_node?(node)
      node.text?
    end
  end

  def scrubber
    PostsHelper::PostScrubber.new
  end
end
