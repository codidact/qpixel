# Provides helper methods for use by views under <tt>ApplicationController</tt> (and by extension, every view).
module ApplicationHelper
  include Warden::Test::Helpers

  ##
  # Is the current user a moderator on the current community?
  # @return [Boolean]
  def moderator?
    user_signed_in? && current_user.at_least_moderator?
  end

  ##
  # Is the current user an admin on the current community?
  # @return [Boolean]
  def admin?
    user_signed_in? && current_user.admin?
  end

  ##
  # Is the current user a standard user (not a moderator or an admin)?
  # @return [Boolean] check result
  def standard?
    !moderator? && !admin?
  end

  ##
  # Checks if the current user has a specified privilege on a post.
  # @param post [Post] A post to use as context for the privilege.
  # @param privilege [String] The +internal_id+ of the privilege to query.
  # @return [Boolean]
  def check_your_post_privilege(post, privilege)
    !current_user.nil? && current_user&.has_post_privilege?(privilege, post)
  end

  ##
  # Check if the current user has a specified privilege.
  # @param privilege [String] The +internal_id+ of the privilege to query.
  # @return [Boolean]
  def check_your_privilege(privilege)
    !current_user.nil? && current_user&.privilege?(privilege)
  end

  ##
  # Utility to add additional query parameters to a URI.
  # @param base_url [String, nil] A base URI to which to add parameters. If none is specified then the request URI for
  #   the current page will be used.
  # @param params [Hash{#to_s => #to_s}] A hash of query parameters to add to the URI.
  # @return [String] The stringified URI.
  def query_url(base_url = nil, **params)
    uri = URI.parse(request.original_url)
    query = Rack::Utils.parse_nested_query uri.query

    unless base_url.nil?
      base_uri = URI.parse(base_url)
      base_query = Rack::Utils.parse_nested_query base_uri.query
      query = query.merge(base_query)
      uri.path = base_uri.path
    end

    query = query.merge(params.to_h { |k, v| [k.to_s, v.to_s] })
    uri.query = query.map { |k, v| "#{k}=#{v}" }.join('&')
    uri.to_s
  end

  def sign_in_link(title)
    link_to title, new_user_session_url
  end

  ##
  # Creates a link to the community's default content license based on site settings.
  # @return [ActiveSupport::SafeBuffer] The result of the +link_to+ call.
  def license_link
    link_to SiteSetting['ContentLicenseName'], SiteSetting['ContentLicenseLink']
  end

  ##
  # Checks if the search parameter specified is the currently active search.
  # @param param [String] The search parameter.
  # @return [Boolean]
  def active_search?(param)
    $active_search_param == param&.to_sym
  end

  ##
  # Creates a panel for display of a single statistic. Used in reports.
  # @param heading [String] A title for the panel.
  # @param value [#to_s] The statistic value.
  # @param caption [String] A short explanatory caption to display.
  # @return [ActiveSupport::SafeBuffer]
  def stat_panel(heading, value, caption: nil)
    tag.div class: 'stat-panel' do
      tag.h4(heading, class: 'stat-panel-heading') +
        (caption.nil? ? '' : tag.span(caption, class: 'stat-panel-caption')) +
        tag.span(value, class: 'stat-value')
    end
  end

  # rubocop:disable Layout/LineLength because obviously rubocop has a problem with documentation

  ##
  # Converts a number to short-form humanized display, i.e. 100,000 = 100k. Parameters as for
  # {ActiveSupport::NumberHelper#number_to_human}[https://www.rubydoc.info/gems/activesupport/ActiveSupport/NumberHelper#number_to_human-instance_method]
  # @return [String, nil] The humanized number.
  def short_number_to_human(*args, **opts)
    opts = { units: { thousand: 'k', million: 'm', billion: 'b', trillion: 't', quadrillion: 'qd' },
             format: '%n%u' }.merge(opts)
    ActiveSupport::NumberHelper.number_to_human(*args, **opts)
  end

  # rubocop:enable Layout/LineLength

  ##
  # Render a markdown string to HTML with consistent options.
  # @param markdown [String] The markdown string to render.
  # @return [String] The rendered HTML string.
  def render_markdown(markdown)
    CommonMarker.render_doc(markdown,
                            [:FOOTNOTES, :LIBERAL_HTML_TAG, :STRIKETHROUGH_DOUBLE_TILDE],
                            [:table, :strikethrough, :autolink]).to_html(:UNSAFE)
  end

  ##
  # Strip Markdown formatting out of a text string to use in plain-text only environments.
  # This isn't a perfect way to strip out Markdown, so it should only be used for non-critical things like
  # page descriptions - things that will later be supplemented by the full formatted content.
  # @param markdown [String] The Markdown string to strip.
  # @return [String] The plain-text equivalent.
  def strip_markdown(markdown)
    # Remove block-level formatting: headers, hr, references, images, HTML tags
    markdown = markdown.gsub(/(?:^#+ +|^-{3,}|^\[[^\]]+\]: ?.+$|^!\[[^\]]+\](?:\([^)]+\)|\[[^\]]+\])$|<[^>]+>)/, '')

    # Remove inline formatting: bold, italic, strike etc.
    markdown = markdown.gsub(/[*_~]+/, '')

    # Remove links and inline images but replace them with their text/alt text.
    markdown.gsub(/!?\[([^\]]+)\](?:\([^)]+\)|\[[^\]]+\])/, '\1')
  end

  ##
  # Returns a list of top-level post type IDs.
  # @return [Array<Integer>]
  def top_level_post_types
    post_type_ids(is_top_level: true)
  end

  ##
  # Returns a list of second-level post type IDs.
  # @return [Array<Integer>]
  def second_level_post_types
    post_type_ids(is_top_level: false, has_parent: true)
  end

  ##
  # Gets a shareable URL to the specified post, taking into account post type.
  # @param post [Post] The post in question.
  # @return [String]
  def generic_share_link(post)
    if second_level_post_types.include?(post.post_type_id)
      answer_post_url(id: post.parent_id, answer: post.id, anchor: "answer-#{post.id}")
    else
      post_url(post)
    end
  end

  ##
  # Get a shareable link to the specified post in Markdown format.
  # @param post [Post] The post in question.
  # @return [String] The Markdown-formatted link.
  def generic_share_link_md(post)
    "[#{post.title}](#{generic_share_link(post)})"
  end

  ##
  # Get a shareable link to a point in the specified post's history.
  # @param post [Post] The post in question.
  # @param history [ActiveRecord::Collection<PostHistory>] The post's history.
  # @param index [Integer] The index of the history event to link to.
  # @return [String]
  def post_history_share_link(post, history, index)
    post_history_url(post, anchor: history.size - index)
  end

  ##
  # Get a shareable link to a point in the specified post's history, in Markdown form.
  # Parameters as for {#post_history_share_link}.
  def post_history_share_link_md(post, history, index)
    rev_num = history.size - index
    "[Revision #{rev_num} — #{post.title}](#{post_history_share_link(post, history, index)})"
  end

  ##
  # Get a link to edit the specified post.
  # @param post [Post] The post to link to.
  # @return [String]
  def generic_edit_link(post)
    edit_post_url(post)
  end

  ##
  # Get a link to the specified post. Also works for help and policy documents.
  # @param post [Post] The post to link to.
  # @return [String]
  def generic_show_link(post)
    if top_level_post_types.include? post.post_type_id
      post_url(post)
    elsif second_level_post_types.include?(post.post_type_id)
      post_url(post.parent, anchor: "answer-#{post.id}")
    else
      case post.post_type_id
      when HelpDoc.post_type_id
        help_url(post.doc_slug)
      when PolicyDoc.post_type_id
        policy_url(post.doc_slug)
      else
        '#'
      end
    end
  end

  ##
  # Split a string after a specified number of characters, only breaking at word boundaries.
  # @param text [String] The text to split.
  # @param max_length [Integer] The maximum number of characters to leave in the resulting strings.
  # @return [Array<String>]
  def split_words_max_length(text, max_length)
    words = text.split
    splat = [[]]
    words.each do |word|
      # Unless the current last element has enough space to take the extra word, create a new one.
      unless splat[-1].map { |w| w.length + 1 }.sum - 1 <= max_length - word.length
        splat << []
      end
      splat[-1] << word
    end
    splat.map { |s| s.join(' ') }
  end

  ##
  # Check if the specified item is deleted.
  # @param item [ApplicationRecord] The item to check.
  # @return [Boolean]
  def deleted_item?(item)
    case item.class.to_s
    when 'Post', 'Comment', 'CommunityUser'
      item.deleted
    when 'User'
      item.deleted || item.community_user.deleted
    else
      false
    end
  end

  ##
  # Translate a given string using {I18n#t}[https://www.rubydoc.info/gems/i18n/I18n/Base#translate-instance_method],
  # after substituting values into the string based on a hash.
  # @param key [String, Symbol] The translation key as passed to I18n#t.
  # @param subs [Hash{#to_s => #to_s}] A list of substitutions to apply - keys of the form +:name+ in the string should
  #   have a corresponding +name+ entry in this hash and will be substituted for the value.
  # @return [String]
  # @example
  #   # In I18n config:
  #   # user_post_count: 'You have :count posts on this community.'
  #   helpers.i18ns('user_post_count', count: @posts.size)
  #   # => 'You have 23 posts on this community.'
  #   # or as appropriate based on locale
  def i18ns(key, **subs)
    s = I18n.t key
    subs.each do |f, r|
      s = s.gsub ":#{f}", r.to_s
    end
    s
  end

  ##
  # Get a list of network promoted posts, ignoring expired entries.
  # @return [Hash{Integer => Integer}] A hash of post IDs as keys, and Unix entry timestamp as values.
  def promoted_posts
    JSON.parse(RequestContext.redis.get('network/promoted_posts') || '{}')
        .select { |_k, v| DateTime.now.to_i - v <= 3600 * 24 * 28 }
  end

  ##
  # Is the network in read-only mode?
  # @return [Boolean]
  def read_only?
    RequestContext.redis.get('network/read_only') == 'true'
  end

  ##
  # Redefined Devise current_user helper. Additionally checks for deleted users - if the current user has been soft
  # deleted, this will sign them out. As +current_user+ is called on every page in the header, this has the effect of
  # immediately signing the user out even if they're signed in when their account is deleted.
  # @return [User, nil]
  def current_user
    return nil unless defined?(warden)

    @current_user ||= warden.authenticate(scope: :user)
    if @current_user&.deleted? || @current_user&.community_user&.deleted?
      scope = Devise::Mapping.find_scope!(:user)
      logout scope
      @current_user = nil
    end
    @current_user
  end

  ##
  # Is there a user signed in on this request?
  # @return [Boolean]
  def user_signed_in?
    !!current_user && !current_user.deleted? && !current_user.community_user&.deleted?
  end

  # Check if the current request is a direct user request, or a resource load.
  # @return [Boolean, nil] true if the request is direct, false if not, or nil if it cannot be determined
  def direct_request?
    if request.headers['Sec-Fetch-Mode'].present? && request.headers['Sec-Fetch-Mode'] == 'navigate'
      true
    elsif request.headers['Sec-Fetch-Mode'].present?
      false
    end
  end

  ##
  # Get the current active commit information to display in the footer.
  # @return [Array(String, DateTime)] Two values: the commit hash and the timestamp.
  def current_commit
    commit_info = Rails.cache.persistent('current_commit')
    shasum, timestamp = commit_info

    begin
      date = DateTime.iso8601(timestamp)
    rescue
      date = DateTime.parse(timestamp)
    end

    [shasum, date]
  rescue
    [nil, nil]
  end
end
