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
                            [:table, :strikethrough, :autolink]).to_html(:UNSAFE)
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

  def generic_share_link(post)
    case post.post_type_id
    when Question.post_type_id
      share_question_url(post)
    when Answer.post_type_id
      share_answer_url(qid: post.parent_id, id: post.id)
    when Article.post_type_id
      share_article_url(post)
    else
      '#'
    end
  end

  def generic_edit_link(post)
    case post.post_type_id
    when Question.post_type_id
      edit_question_url(post)
    when Answer.post_type_id
      edit_answer_url(post)
    when Article.post_type_id
      edit_article_url(post)
    else
      '#'
    end
  end

  def generic_show_link(post)
    case post.post_type_id
    when Question.post_type_id
      question_url(post)
    when Article.post_type_id
      article_url(post)
    else
      '#'
    end
  end

  def split_words_max_length(text, max_length)
    words = text.split ' '
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

  def deleted_item?(item)
    case item.class.to_s
    when 'Post'
      item.deleted
    when 'Comment'
      item.deleted
    when 'PostHistory'
      false
    else
      false
    end
  end

  def is_rtl_override(char)
    # rtl_override_hex = '\u202E'
    char_bytes = char.bytes
    if char_bytes.length() != 3
      return false
    end
    if char_bytes[0] != 226  # 0xE2
      return false
    end
    if char_bytes[1] != 128  # 0x80
      return false
    end
    if char_bytes[2] != 174  # 0xAE
      return false
    end
    return true
  end

  def sanitize_username(username)
    return username
  end

  def directional_formatting_pops_after_username_ct(username)
    if is_rtl_override(username[0])
      # pop_directional_formatting_hex = '\u202C'
      return 1
    end
    return 0
  end
end
