# Provides helper methods for use by views under <tt>UsersController</tt>.
module UsersHelper
  def avatar_url(user, size=16)
    user = user || current_user
    user&.avatar&.attached? ? url_for(user.avatar) : "https://unicornify.pictures/avatar/#{user.id}?s=#{size}"
  end
end
