module MarkdownToolsHelper
  ##
  # Create a Markdown tool button.
  # @param name [String] A name to display on the button. If you want to use an icon instead, pass a block and leave
  #   +name+ as +nil+ (default).
  # @param action [String] Populates the button's +data-action+ attribute, which can be processed later via Markdown JS.
  # @param label [String] Populates the button's +title+ and +aria-label+ attributes.
  # @param attribs [Hash{#to_s => Object}] A hash of additional attributes to pass to the tag generator.
  # @yieldparam context [ActionView::Helpers::TagHelper::TagBuilder]
  # @yieldreturn [String, ActiveSupport::SafeBuffer]
  # @return [ActiveSupport::SafeBuffer]
  # @example Create a Bold button with icon:
  #   <%= md_button action: 'bold', label: 'Bold', data: { index: 1 } do %>
  #     <i class="fas fa-bold"></i>
  #   <% end %>
  #
  #   # => <a class="button is-muted is-outlined js-markdown-tool" data-action="bold" data-index="1" aria-label="Bold"
  #           role="button">
  #          <i class="fas fa-bold"></i>
  #        </a>
  def md_button(name = nil, action: nil, label: nil, **attribs, &block)
    attribs.merge! href: 'javascript:void(0)',
                   class: "#{attribs[:class] || ''} button is-muted is-outlined js-markdown-tool",
                   data_action: action,
                   aria_label: label,
                   title: label,
                   role: 'button'
    attribs.transform_keys! { |k| k.to_s.tr('_', '-') }.symbolize_keys!
    if name.nil? && block_given?
      tag.a(**attribs, &block)
    else
      tag.a name, **attribs
    end
  end

  # Create a Markdown tool list item. Identical to
  # @param (see #md_button)
  # @yieldparam (see #md_button)
  # @yieldreturn (see #md_button)
  # @return (see #md_button)
  def md_list_item(name = nil, action: nil, label: nil, **attribs, &block)
    attribs.merge! href: 'javascript:void(0)',
                   class: "#{attribs[:class] || ''}js-markdown-tool",
                   data_action: action,
                   aria_label: label,
                   title: label,
                   role: 'button'
    attribs.transform_keys! { |k| k.to_s.tr('_', '-') }.symbolize_keys!
    if name.nil? && block_given?
      tag.a(**attribs, &block)
    else
      tag.a name, **attribs
    end
  end
end
