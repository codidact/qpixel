# Provides helper methods for use by views under <tt>UsersController</tt>.
module UsersHelper
  ##
  # Get a URL to the avatar for the selected user.
  # @param user [User]
  # @param size [Integer] Image side length, in pixels. Does not apply to uploaded avatars - size attributes must still
  #   be set in HTML.
  # @return [String]
  def avatar_url(user, size = 16)
    if deleted_user?(user)
      user_auto_avatar_url(letter: 'X', color: '#E73737FF', size: size, format: :png)
    elsif user&.avatar&.attached?
      uploaded_url(user.avatar.blob.key)
    else
      user_auto_avatar_url(user, size: size, format: :png)
    end
  end

  ##
  # Get an OAuth URL to Stack Exchange.
  # @return [String]
  def stack_oauth_url
    "https://stackoverflow.com/oauth?client_id=#{SiteSetting['SEApiClientId']}" \
      "&scope=&redirect_uri=#{stack_redirect_url}"
  end

  ##
  # Can the specified user change a post's category to the specified target category?
  # @param user [User]
  # @param target [Category]
  # @return [Boolean]
  def can_change_category(user, target)
    user.privilege?('flag_curate') &&
      (user.is_moderator || user.is_admin || target.min_trust_level.nil? || target.min_trust_level <= user.trust_level)
  end

  ##
  # Generate <select> options for a user preference with a custom +choice+ defined in preferences.yml.
  # @return [Array<Array<String, String>>]
  def preference_choice(pref_config)
    pref_config['choice'].map do |c|
      if c.is_a? Hash
        [c['name'], c['value']]
      else
        [c.humanize, c]
      end
    end
  end

  ##
  # Get the default filter for the specified user and category.
  # @param user_id [Integer]
  # @param category_id [Category]
  # @return [Filter, nil]
  def default_filter(user_id, category_id)
    CategoryFilterDefault.find_by(user_id: user_id, category_id: category_id)&.filter
  end

  ##
  # Set a default filter for the specified user and category. Can also be used to remove a default filter.
  # @param user_id [Integer]
  # @param filter_id [Integer]
  # @param category_id [Integer]
  # @param keep [Boolean] Pass +true+ to set a new default; pass +false+ to remove the default for the specified user
  #   and category.
  # @return [ActiveRecord::Relation<CategoryFilterDefault>]
  def set_filter_default(user_id, filter_id, category_id, keep)
    if keep
      CategoryFilterDefault.create_with(filter_id: filter_id)
                           .find_or_create_by(user_id: user_id, category_id: category_id)
                           .update(filter_id: filter_id)
    else
      CategoryFilterDefault.where(user_id: user_id, category_id: category_id)
                           .destroy_all
    end
  end

  ##
  # Get the current user's setting for the specified preference. Returns +nil+ if no user is signed in.
  # @param name [String] The name of the preference to query.
  # @param community [Boolean] Is this a community-specific preference?
  # @return [Object, nil]
  def user_preference(name, community: false)
    return nil if current_user.nil?

    current_user&.preference(name, community: community)
  end

  ##
  # Is the specified user deleted, either globally or on the current community?
  # @param user [User]
  # @return [Boolean, nil] True/false, or +nil+ if the user is +nil+.
  def deleted_user?(user)
    return nil if user.nil?

    user.deleted? || user.community_user&.deleted?
  end

  ##
  # Get a RTL-safe string of the specified user's username. Appends an RTL terminator to the username.
  # @param user [User]
  # @return [String]
  def rtl_safe_username(user)
    deleted_user?(user) ? 'deleted user' : user.rtl_safe_username
  end

  ##
  # Get a link to the specified user's profile.
  # @param user [User]
  # @param url_opts [Hash] Options to pass to +user_url+.
  # @option link_opts :anchortext [String] Custom link text. Remaining +link_opts+ params will be passed to +link_to+.
  # @return [ActiveSupport::SafeBuffer]
  def user_link(user, url_opts = {}, **link_opts)
    anchortext = link_opts[:anchortext]
    link_opts_reduced = { dir: 'ltr' }.merge(link_opts).except(:anchortext)
    if !anchortext.nil?
      link_to anchortext, user_url(user, **url_opts), { dir: 'ltr' }.merge(link_opts)
    elsif deleted_user?(user)
      link_to 'deleted user', '#', link_opts_reduced
    else
      link_to user.rtl_safe_username, user_url(user, **url_opts), link_opts_reduced
    end
  end

  ##
  # Is SSO sign in enabled for the current community?
  # @return [Boolean]
  def sso_sign_in_enabled?
    SiteSetting['SsoSignIn']
  end

  ##
  # Is Devise sign in enabled for the current community?
  # @return [Boolean]
  def devise_sign_in_enabled?
    SiteSetting['MixedSignIn'] || !sso_sign_in_enabled?
  end

  ##
  # Returns a user corresponding to the ID provided, with the caveat that if +user_id+ is 'me' and there is a user
  # signed in, the signed in user will be returned. Use for /users/me links.
  # @param [String] user_id The user ID to find, from +params+
  # @return [User] The User object
  def user_with_me(user_id)
    if user_id == 'me' && user_signed_in?
      current_user
    else
      User.find(user_id)
    end
  end
end
