module SiteSettingsHelper
  def rendered_description(setting)
    sanitize(render_markdown(setting.description))
  end
end
