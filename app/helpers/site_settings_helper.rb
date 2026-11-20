module SiteSettingsHelper
  # Renders description for a given site setting
  # @param setting [SiteSetting] setting to render the description for
  # @return [ActiveSupport::SafeBuffer] rendered description
  def rendered_description(setting)
    raw_description = setting.description || ''
    sanitize(render_markdown(raw_description))
  end

  # Formats max upload size (in bytes) into a human-friendly representation
  # @return [String] formatted value
  def human_max_upload_size
    number_to_human_size(SiteSetting['MaxRequestBodySize'])
  end
end
