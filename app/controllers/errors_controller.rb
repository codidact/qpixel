# Provides web actions that represent errors. Rails' standard error pages are static HTML with inline CSS; by using
# a custom error controller we get all the layouts and CSS.
class ErrorsController < ApplicationController
  def error
    @exception = request.env['action_dispatch.exception']
    @status = ActionDispatch::ExceptionWrapper.new(request.env, @exception)&.status_code
    views = {
      403 => 'errors/forbidden',
      404 => 'errors/not_found',
      409 => 'errors/conflict',
      418 => 'errors/stat',
      422 => 'errors/unprocessable_entity',
      500 => 'errors/internal_server_error'
    }

    if @exception&.class == ActionView::MissingTemplate
      @status = 404
    end

    if @exception.present? && [422, 500].include?(@status)
      @log = ErrorLog.create(community: RequestContext.community, user: current_user, klass: @exception&.class,
                             message: @exception&.message, backtrace: @exception&.backtrace&.join("\n"),
                             request_uri: request.original_url, host: request.raw_host_with_port,
                             uuid: SecureRandom.uuid, user_agent: request.user_agent)
    end

    render views[@status] || 'errors/error', formats: :html, status: @status, layout: 'without_sidebar'
  end
end
