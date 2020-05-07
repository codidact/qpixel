# Provides helper methods for use by views under <tt>UsersController</tt>.
module UsersHelper
  def avatar_url(user, size = 16)
    user ||= current_user
    if user&.avatar&.attached?
      uploaded_url(user.avatar.blob.key)
    else
      "https://unicornify.pictures/avatar/#{user.id}?s=#{size}"
    end
  end

  def stack_oauth_url
    "https://stackoverflow.com/oauth?client_id=#{SiteSetting['SEApiClientId']}" \
    "&scope=&redirect_uri=#{stack_redirect_url}"
  end
end
