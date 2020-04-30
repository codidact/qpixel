# Provides web actions that represent errors. Rails' standard error pages are static HTML with inline CSS; by using
# a custom error controller we get all the layouts and CSS.
class ErrorsController < ApplicationController
  def error
    @exception = request.env['action_dispatch.exception']
    @status = ActionDispatch::ExceptionWrapper.new(request.env, @exception).status_code
    views = {
      403 => 'errors/forbidden',
      404 => 'errors/not_found',
      409 => 'errors/conflict',
      422 => 'errors/unprocessable_entity',
      500 => 'errors/internal_server_error'
    }
    puts "  Error type #{@exception.class}, status code #{@status}"
    render views[@status] || 'errors/error', formats: :html, status: @status, layout: 'without_sidebar'
  end
end
