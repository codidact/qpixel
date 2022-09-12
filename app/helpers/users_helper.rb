# Provides helper methods for use by views under <tt>UsersController</tt>.
module UsersHelper
  def avatar_url(user, size = 16)
    if deleted_user?(user)
      user_auto_avatar_url(letter: 'X', color: '#E73737FF', size: size, format: :png)
    elsif user&.avatar&.attached?
      url_for(user.avatar.variant(resize_to_fit: [size, size]).processed)
    else
      user_auto_avatar_url(user, size: size, format: :png)
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

  def deleted_user?(user)
    user.nil? || user.deleted? || user.community_user&.deleted?
  end

  def rtl_safe_username(user)
    deleted_user?(user) ? 'deleted user' : user.rtl_safe_username
  end

  def user_link(user, **link_opts)
    if deleted_user?(user)
      link_to 'deleted user', '#', { dir: 'ltr' }.merge(link_opts)
    else
      link_to user.rtl_safe_username, user_url(user), { dir: 'ltr' }.merge(link_opts)
    end
  end
end
