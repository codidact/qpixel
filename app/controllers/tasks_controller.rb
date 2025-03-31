class TasksController < ApplicationController
  before_action :check_permissions

  private

  def check_permissions
    # We can't use ApplicationController#verify_developer because it tries to render not_found with
    # layout: 'without_sidebar', which breaks because routing doesn't work under mounted applications. Bleugh.
    if !helpers.user_signed_in? || !helpers.current_user.developer?
      render plain: '403 Forbidden', status: :forbidden
    end
  end
end
