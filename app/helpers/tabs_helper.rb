module TabsHelper
  def tabs
    @building_tabs = []
    yield
    tabs = @building_tabs.join("\n")
    @building_tabs = []
    tag.div raw(tabs), class: 'tabs'
  end

  def tab(text, link_url, **opts, &block)
    active = opts[:is_active] || false
    opts.delete :is_active
    opts[:class] = if opts[:class]
                     "#{opts[:class]} tabs--tab#{active ? ' tab__active' : ''}"
                   else
                     "tabs--tab#{active ? ' tab__active' : ''}"
                   end

    @building_tabs << if block_given?
                        link_to link_url, **opts, &block
                      else
                        link_to text, link_url, **opts
                      end
  end
end
