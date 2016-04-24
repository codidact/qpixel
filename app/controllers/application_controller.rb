class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :username) }
    end

    def verify_moderator
      if !user_signed_in? || !(current_user.is_moderator || current_user.is_admin)
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end

    def verify_admin
      if !user_signed_in? || !current_user.is_admin
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end

    def get_setting(name)
      begin
        setting = SiteSetting.find_by_name name
        return setting.value
      rescue
        return nil
      end
    end
end
