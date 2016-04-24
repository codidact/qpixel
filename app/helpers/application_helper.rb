module ApplicationHelper
  def get_setting(name)
    begin
      setting = SiteSetting.find_by_name name
      return setting.value
    rescue
      return nil
    end
  end

  def user_is_mod
    return user_signed_in? && (current_user.is_moderator || current_user.is_admin)
  end

  def user_is_admin
    return user_signed_in? && current_user.is_admin
  end
end
