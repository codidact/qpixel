# Provides helper methods for use by views under <tt>ApplicationController</tt> (and by extension, every view).
module ApplicationHelper
  # Identical to <tt>ApplicationController#get_setting</tt>. Retrieves the value of a site setting based on the name, or
  # <tt>nil</tt> if it couldn't be found.
  def get_setting(name)
    begin
      setting = SiteSetting.find_by_name name
      return setting.value
    rescue
      return nil
    end
  end

  # Similar to <tt>ApplicationController#verify_moderator</tt>, but doesn't raise errors if the user is not a moderator.
  def user_is_mod
    return user_signed_in? && (current_user.is_moderator || current_user.is_admin)
  end

  # Similar to <tt>ApplicationController#verify_admin</tt>, but doesn't raise errors. Simply returns yea or nay.
  def user_is_admin
    return user_signed_in? && current_user.is_admin
  end
end
