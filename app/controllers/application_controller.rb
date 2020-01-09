# Application controller. This is the overarching control center for the application, which every web controller
# inherits from. Any application-wide code-based configuration is done here, as well as providing controller helper
# methods and global callbacks.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_globals

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :profile, :website, :twitter])
  end

  def not_found
    render 'errors/not_found', layout: 'errors', status: 404
  end

  def verify_moderator
    if !user_signed_in? || !(current_user.is_moderator || current_user.is_admin)
      render 'errors/not_found', layout: 'errors', status: 404
      return false
    end
    true
  end

  def verify_admin
    if !user_signed_in? || !current_user.is_admin
      render 'errors/not_found', layout: 'errors', status: 404
      return false
    end
    true
  end

  def check_your_privilege(name, post = nil, render_error = true)
    unless current_user&.has_privilege?(name) || (current_user&.has_post_privilege?(name, post) if post)
      @privilege = Privilege.find_by(name: name)
      render 'errors/forbidden', layout: 'errors', privilege_name: name, status: 401 if render_error
      return false
    end
    true
  end

  private

  def set_globals
    if current_user.nil?
      Rails.logger.info 'No user signed in'
    else
      Rails.logger.info "User #{current_user.id} (#{current_user.username}) signed in"
    end

    @hot_questions = Rails.cache.fetch("hot_questions", expires_in: 30.minutes) do
      Question.undeleted.where(updated_at: (Rails.env.development? ? 365 : 1).days.ago..Time.now)
              .order('score DESC').limit(SiteSetting['HotQuestionsCount'])
    end
    if user_signed_in? && (current_user.is_moderator || current_user.is_admin)
      @open_flags = Flag.unhandled.count
    end

    if !user_signed_in? && cookies[:dismiss_fvn] != 'true'
      @first_visit_notice = true
    else
      @first_visit_notice = false
    end
  end
end
