module MicroAuth::AppsHelper
  ##
  # Builds & returns a tag-style badge indicating whether a specified app is active for use or not.
  # @param app [MicroAuth::App] The app for which to build a badge.
  # @return [ActiveSupport::SafeBuffer] A badge; the result of a TagBuilder.
  def app_active_badge(app)
    tag.span app.active? ? 'active' : 'inactive',
             class: "badge is-tag #{app.active? ? 'is-green' : 'is-red'}"
  end
end
