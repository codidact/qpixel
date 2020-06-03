# Provides helper methods for use by views under <tt>ApplicationController</tt> (and by extension, every view).
module ApplicationHelper
  def moderator?
    user_signed_in? && (current_user.is_moderator || current_user.is_admin)
  end

  def admin?
    user_signed_in? && current_user.is_admin
  end

  def check_your_post_privilege(post, privilege)
    current_user&.has_post_privilege?(privilege, post)
  end

  def check_your_privilege(privilege)
    current_user&.has_privilege?(privilege)
  end

  def query_url(base_url = nil, **params)
    uri = URI.parse(request.original_url)
    query = Rack::Utils.parse_nested_query uri.query

    unless base_url.nil?
      base_uri = URI.parse(base_url)
      base_query = Rack::Utils.parse_nested_query base_uri.query
      query = query.merge(base_query)
      uri.path = base_uri.path
    end

    query = query.merge(params.map { |k, v| [k.to_s, v.to_s] }.to_h)
    uri.query = query.map { |k, v| "#{k}=#{v}" }.join('&')
    uri.to_s
  end

  def license_link
    link_to SiteSetting['ContentLicenseName'], SiteSetting['ContentLicenseLink']
  end

  def active_search?(param)
    $active_search_param == param&.to_sym
  end

  def stat_panel(heading, value)
    tag.div class: 'panel panel-default stat-panel' do
      tag.div class: 'panel-body' do
        tag.h4(heading, class: 'stat-panel-heading') +
          tag.span(value, class: 'stat-value')
      end
    end
  end

  def short_number_to_human(*args, **opts)
    opts = { units: { thousand: 'k', million: 'm', billion: 'b', trillion: 't', quadrillion: 'qd' },
             format: '%n%u' }.merge(opts)
    ActiveSupport::NumberHelper.number_to_human(*args, **opts)
  end

  def render_markdown(markdown)
    CommonMarker.render_doc(markdown,
                            [:FOOTNOTES, :LIBERAL_HTML_TAG, :STRIKETHROUGH_DOUBLE_TILDE],
                            [:table, :strikethrough, :autolink]).to_html
  end

  # This isn't a perfect way to strip out Markdown, so it should only be used for non-critical things like
  # page descriptions - things that will later be supplemented by the full formatted content.
  def strip_markdown(markdown)
    # Remove block-level formatting: headers, hr, references, images, HTML tags
    markdown = markdown.gsub(/(?:^#+ +|^-{3,}|^\[[^\]]+\]: ?.+$|^!\[[^\]]+\](?:\([^)]+\)|\[[^\]]+\])$|<[^>]+>)/, '')

    # Remove inline formatting: bold, italic, strike etc.
    markdown = markdown.gsub(/[*_~]+/, '')

    # Remove links and inline images but replace them with their text/alt text.
    markdown = markdown.gsub(/!?\[([^\]]+)\](?:\([^)]+\)|\[[^\]]+\])/, '\1')

    markdown
  end
end
