module PostsHelper
  ##
  # Get HTML for a field - should only be used in Markdown create/edit requests. Prioritises using the client-side
  # rendered HTML over rendering server-side.
  # @param scope [Symbol] The parameter scope for the markdown - i.e. if the form submits it as +posts[body_markdown]+,
  #   this should be +:posts+.
  # @param field_name [Symbol] The parameter name for the markdown - i.e. +:body_markdown+ in the same example.
  # @return [String]
  def rendered_post(scope, field_name)
    if params['__html'].present? && params['__html'] != '<!-- g: js, mdit -->'
      params['__html']
    else
      render_markdown params[scope][field_name]
    end
  end

  ##
  # Get the redirect path to use when the user cancels an edit.
  # @return [String]
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

  ##
  # Get the minimum body length for the specified category.
  # @param category [Category, nil]
  # @return [Integer]
  def min_body_length(category)
    category&.min_body_length || 30
  end

  ##
  # Get the maximum body length for the specified category. Returns a constant 30,000 at present but intended to return
  # a configurable value in the future.
  # @param _category [Category, nil]
  # @return [Integer]
  def max_body_length(_category)
    30_000
  end

  ##
  # Get the minimum title length for the specified category.
  # @param category [Category, nil]
  # @param post_type [PostType] Type of the post (system limits are relaxed)
  # @return [Integer]
  def min_title_length(category, post_type)
    if post_type.system?
      1
    else
      category&.min_title_length || 15
    end
  end

  ##
  # Get the maximum title length for the specified category. Has a hard limit of 255 characters.
  # @param _category [Category, nil]
  # @return [Integer]
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

  ##
  # Get a post scrubber instance.
  # @return [PostScrubber]
  def scrubber
    PostsHelper::PostScrubber.new
  end
end
