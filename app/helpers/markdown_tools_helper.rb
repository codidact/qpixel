module MarkdownToolsHelper
  def md_button(name = nil, **attribs)
    attribs.merge! href: 'javascript:void(0)',
                   class: (attribs[:class] || '') + ' button is-muted is-outlined'
    attribs.transform_keys! { |k| k.to_s.tr('_', '-') }.symbolize_keys!
    if name.nil? && block_given?
      tag.a **attribs do
        yield
      end
    else
      tag.a name, **attribs
    end
  end
end