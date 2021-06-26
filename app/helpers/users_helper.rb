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

  def can_change_category(user, target)
    user.privilege?('flag_curate') &&
      (user.is_moderator || user.is_admin || target.min_trust_level.nil? || target.min_trust_level <= user.trust_level)
  end

  def preference_choice(pref_config)
    pref_config['choice'].map do |c|
      if c.is_a? Hash
        [c['name'], c['value']]
      else
        [c.humanize, c]
      end
    end
  end

  def user_preference(name, community: false)
    return nil if current_user.nil?

    current_user.preference(name, community: community)
  end
end
