module PostsHelper
  def post_markdown(scope, field_name)
    params['__html'].presence || render_markdown(params[scope][field_name])
  end

  def cancel_redirect_path(post)
    if post.id.present?
      post_url(post)
    elsif post.parent_id.present?
      post_url(post.parent_id)
    elsif post.category_id.present?
      category_url(post.category_id)
    else
      root_url
    end
  end

  # @param category [Category, Nil]
  # @return [Integer] the minimum length for post bodies
  def min_body_length(category)
    category&.min_body_length || 30
  end

  # @param _category [Category, Nil]
  # @return [Integer] the maximum length for post bodies
  def max_body_length(_category)
    30_000
  end

  # @param category [Category, Nil] post category, if any
  # @param post_type [PostType] type of the post (system limits are relaxed)
  # @return [Integer] the minimum length for post titles
  def min_title_length(category, post_type)
    if post_type.system?
      1
    else
      category&.min_title_length || 15
    end
  end

  # @param _category [Category, Nil]
  # @return [Integer] the maximum length for post titles
  def max_title_length(_category)
    [SiteSetting['MaxTitleLength'] || 255, 255].min
  end

  class PostScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      # IF YOU CHANGE THESE VALUES YOU MUST ALSO CHANGE app/assets/javascripts/posts.js
      self.tags = %w[a p span b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li sup sub
                     section details summary ins table thead tbody tr th td s]
      self.attributes = %w[id class href title src height width alt rowspan colspan lang start dir]
    end

    def skip_node?(node)
      node.text?
    end
  end

  def scrubber
    PostsHelper::PostScrubber.new
  end
end
