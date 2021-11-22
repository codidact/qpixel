# Provides helper methods for use by views under <tt>ModeratorController</tt>.
module ModeratorHelper
  def text_bg(cls, content = nil, **opts, &block)
    if block_given?
      tag.span class: ["has-background-color-#{cls}", opts[:class]].join(' '), &block
    else
      tag.span content, class: ["has-background-color-#{cls}", opts[:class]].join(' ')
    end
  end
end
