module SiteSettingsHelper
  # Renders description for a given site setting
  # @param setting [SiteSetting] setting to render the description for
  # @return [ActiveSupport::SafeBuffer] rendered description
  def rendered_description(setting)
    raw_description = setting.description || ''
    sanitize(render_markdown(raw_description))
  end
end
