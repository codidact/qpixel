module MicroAuth::AppsHelper
  def app_active_badge(app)
    tag.span app.active? ? 'active' : 'inactive',
             class: "badge is-tag #{app.active? ? 'is-green' : 'is-red'}"
  end
end
