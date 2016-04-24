class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected
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
