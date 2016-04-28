# Provides web actions that represent errors. Rails' standard error pages are static HTML with inline CSS; by using
# a custom error controller we get all the layouts and CSS.
class ErrorsController < ApplicationController
  # Provides a 404 Not Found error response.
  def not_found
    render :status => 404
  end

  # Provides a 403 Forbidden error response.
  def forbidden
    if params[:privilege_name]
      @privilege = Privilege.find_by_name params[:privilege_name]
    end
    render :status => 403
  end

  # Provides a 422 Unprocessable Entity error response.
  def unprocessable_entity
    render :status => 422
  end

  # Provides a 409 Conflict error response.
  def conflict
    render :status => 409
  end

  # Provides a 500 Internal Server Error error response.
  def internal_server_error
    render :status => 500
  end
end
