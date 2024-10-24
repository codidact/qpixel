# Provides helper methods for use by views under <tt>ModeratorController</tt>.
module ModeratorHelper
  ##
  # Display text on a specified background color.
  # @param cls [String] The background color class.
  # @param content [String] The text to display. For uses beyond simple text, pass a block instead.
  # @option opts :class [String] Additional classes to add to the element. For instance, if the background color is dark,
  #   consider passing a class for a light text color.
  # @yieldparam context [ActionView::Helpers::TagHelper::TagBuilder]
  # @yieldreturn [ActiveSupport::SafeBuffer, String]
  # @return [ActiveSupport::SafeBuffer]
  def text_bg(cls, content = nil, **opts, &block)
    if block_given?
      tag.span class: ["has-background-color-#{cls}", opts[:class]].join(' '), &block
    else
      tag.span content, class: ["has-background-color-#{cls}", opts[:class]].join(' ')
    end
  end
end
