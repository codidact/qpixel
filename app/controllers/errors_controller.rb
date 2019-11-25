# Provides web actions that represent errors. Rails' standard error pages are static HTML with inline CSS; by using
# a custom error controller we get all the layouts and CSS.
class ErrorsController < ApplicationController
  def not_found
    render status: 404
  end

  def forbidden
    if params[:privilege_name]
      @privilege = Privilege.find_by_name params[:privilege_name]
    end
    render status: 403
  end

  def unprocessable_entity
    render status: 422
  end

  def conflict
    render status: 409
  end

  def internal_server_error
    render status: 500
  end
end
