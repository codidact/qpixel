# Provides helper methods for use by views under <tt>ApplicationController</tt> (and by extension, every view).
module ApplicationHelper
  # Similar to <tt>ApplicationController#verify_moderator</tt>, but doesn't raise errors if the user is not a moderator.
  def user_is_mod
    user_signed_in? && (current_user.is_moderator || current_user.is_admin)
  end

  # Similar to <tt>ApplicationController#verify_admin</tt>, but doesn't raise errors. Simply returns yea or nay.
  def user_is_admin
    user_signed_in? && current_user.is_admin
  end

  # Basically identical to <tt>ApplicationController#check_your_post_privilege</tt> (sorry, I had to call it that), but
  # as a helper for views.
  def check_your_post_privilege(post, privilege)
    current_user&.has_post_privilege?(privilege, post)
  end

  # Basically identical to <tt>ApplicationController#check_your_privilege</tt>, but again as a helper for views.
  def check_your_privilege(privilege)
    current_user&.has_privilege?(privilege)
  end
end
