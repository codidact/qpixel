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
    # Re-configures the parameters that the Devise parameter sanitizer will allow through. By default, this is only the
    # default user fields. We additionally have a username, which needs to be allowed through. This method is called
    # before every action taken from a Devise (or inherited Devise, such as app/controllers/users/*) controller.
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up) do |user|
        user.permit(:email, :password, :password_confirmation, :username)
      end
    end

    # Verifies that the currently signed in user is, in fact, a moderator. This method assumes that it is used as a
    # before_action callback on a mod-protected resource, so in the event that the user is not a moderator, a 404 Not
    # Found error is thrown. Also assumes that administrators have access to moderator resources, so returns true for
    # administrators.
    def verify_moderator
      if !user_signed_in? || !(current_user.is_moderator || current_user.is_admin)
        render template: 'errors/not_found', status: 404 and return
      end
    end

    # Very similar to verify_moderator. Verifies that the currently signed in user is an administrator; throws a 404
    # Not Found if not. Admins are assumed to be a higher level than moderators, so returns false for moderators.
    def verify_admin
      if !user_signed_in? || !current_user.is_admin
        render template: 'errors/not_found', status: 404 and return
      end
    end

    # Retrieves the value of the site setting specified by <tt>name</tt>. This method is essentially a helper method
    # for controllers; it is not intended as a callback action but rather as a procedural method call. Returns
    # <tt>nil</tt> if the setting is not found; this is usually preferable to raising a processing error and having the
    # server return 500 Internal Server Error for an error that is usually recoverable.
    def get_setting(name)
      begin
        setting = SiteSetting.find_by_name name
        return setting.value
      rescue
        return nil
      end
    end

    def check_your_privilege(name, post = nil, render_error = true)
      unless current_user&.has_privilege?(name) || (current_user&.has_post_privilege?(name, post) if post)
        @privilege = Privilege.find_by(name: name)
        render 'errors/forbidden', layout: 'errors', privilege_name: name, status: 401 if render_error
        return false
      end
      return true
    end

  private
    def set_globals
      @hot_questions = Rails.cache.fetch("hot_questions", expires_in: 30.minutes) do
        Question.where(updated_at: 1.day.ago..Time.now).order('score DESC').limit(get_setting('HotQuestionsCount').to_i)
      end
      if user_signed_in? && (current_user.is_moderator || current_user.is_admin)
        @open_flags = Flag.joins('left outer join flag_statuses on flags.id = flag_statuses.flag_id').where('flag_statuses.id is null').count
      end
    end
end
