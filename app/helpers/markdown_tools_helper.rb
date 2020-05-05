module MarkdownToolsHelper
  def md_button(name = nil, action: nil, label: nil, **attribs)
    attribs.merge! href: 'javascript:void(0)',
                   class: (attribs[:class] || '') + ' button is-muted is-outlined js-markdown-tool',
                   data_action: action,
                   aria_label: label,
                   title: label
    attribs.transform_keys! { |k| k.to_s.tr('_', '-') }.symbolize_keys!
    if name.nil? && block_given?
      tag.a(**attribs) do
        yield
      end
    else
      tag.a name, **attribs
    end
  end
end
