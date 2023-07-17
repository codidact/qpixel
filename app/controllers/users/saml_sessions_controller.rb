class Users::SamlSessionsController < Devise::SamlSessionsController
  # Called when someone is redirected to sign into the application using SSO/SAML.
  def new
    # If this is not the base community, then redirect them there for the sign in
    base = base_community
    if base.id != RequestContext.community_id
      redirect_to "//#{base.host}#{sign_in_request_from_other_path(RequestContext.community_id)}",
                  allow_other_host: true
      return
    end

    # If we are the base community, use normal behavior
    super
  end

  # This method is almost the same code as the Users::SessionsController#create, and any changes
  # made here should probably also be applied over there.
  def create
    super do |user|
      return unless post_sign_in(user, false)

      # SSO Only - Redirect to filler endpoint to actually get the clients cookie values (not sent to us here).
      # We need to check cookies because we may be signing in for another community.
      redirect_to after_sign_in_check_path
      return
    end
  end

  # On the initial return from the SSO the client does not send along its cookies (CORS/CSRF/XSS protections).
  # Instead, we redirect the user after the sign-in to this endpoint, such that we get their cookies.
  # Then we can check whether we were supposed to sign them in for a different community.
  def after_sign_in_check
    if cookies.encrypted[:signing_in_for].present? &&
       cookies.encrypted[:signing_in_for] != RequestContext.community_id
      handle_sign_in_for_other_community(current_user)
      return
    end

    return unless post_sign_in(current_user, true)

    redirect_to after_sign_in_path_for(current_user)
  end

  # Another community requests to sign in via this community.
  def sign_in_request_from_other
    # Check whether the requested community actually exists
    unless Community.exists?(params[:id])
      raise ArgumentError, 'User is trying to sign in to non-existing community'
    end

    # Store in a cookie which community we are signing in for such that we can redirect back after the sign in.
    cookies.encrypted[:signing_in_for] = {
      value: params[:id],
      httponly: true,
      expires: 15.minutes.from_now
    }

    # If already signed in, sign them in in the other community as well. Otherwise redirect to SAML sign in.
    if user_signed_in?
      handle_sign_in_for_other_community(current_user)
    else
      redirect_to new_saml_user_session_path
    end
  end

  # User was signed in at the base community, now sign in here.
  def sign_in_return_from_base
    # Figure out which user was signed in.
    # If we get a blank result then the message is either too old or the user messed with it.
    user_info = decrypt_user_info(params[:message])
    if user_info.blank?
      flash[:notice] = nil
      flash[:danger] = 'Something went wrong signing in, please try again.'
      redirect_to root_path
    end

    # Determine the user we are trying to sign in as and report error if we can't
    user = User.find(user_info)
    if user.nil?
      flash[:notice] = nil
      flash[:danger] = 'Something went wrong signing in, please contact support.'
      redirect_to root_path
    end

    # Actually sign in the user and handle the post-sign-in behavior
    sign_in(user)
    return unless post_sign_in(user, true)

    # Finish with default devise behavior for sign ins
    redirect_to after_sign_in_path_for(user)
  end

  private

  # After a sign in, this method is called to check whether special conditions apply to the user.
  # The user may be signed out by this method.
  #
  # In general, this method should have similar behavior to the Users::SessionsController#post_sign_in method.
  # If you make changes here, you may also have to update that method.
  #
  # @param user [User]
  # @param final_destination [Boolean] whether the current community is the one the user is trying to sign into
  # @return [Boolean] false if the user was redirected by this
  def post_sign_in(user, final_destination = false)
    # If the user was banished, let them know non-specifically.
    if user.deleted? || user.community_user&.deleted?
      # The IDP already confirmed the sign in, so we can't fool the user any more that their credentials were incorrect.
      sign_out user
      flash[:notice] = nil
      flash[:danger] = 'We could not sign you in because of an issue with your account.'
      redirect_to root_path
      return false
    end

    # Enforce 2fa if enabled for SSO users
    if SiteSetting['Enable2FAForSsoUsers'] && user.enabled_2fa
      if final_destination
        handle_2fa_login(user)
        return false
      else
        # User needs to do 2FA, but we are (potentially) signing in for a different community.
        # Sign them out and continue the sign in process, when they reach the final destination we will do 2FA there.
        sign_out user
        return true
      end
    end

    true
  end

  def handle_2fa_login(user, host = nil)
    host ||= request.hostname
    sign_out user
    case user.two_factor_method
    when 'app'
      id = user.id
      Users::SessionsController.first_factor << id
      redirect_to login_verify_2fa_path(uid: id)
    when 'email'
      TwoFactorMailer.with(user: user, host: host).login_email.deliver_now
      flash[:notice] = nil
      flash[:info] = 'Please check your email inbox for a link to sign in.'
      redirect_to root_path
    end
  end

  # Handles a successful sign in at the base community when it was requested to do from another community.
  # @param user [User]
  def handle_sign_in_for_other_community(user)
    # Determine which community we are signing in for, log out if not found (user messed with encrypted cookie/expired)
    community = Community.find(cookies.encrypted[:signing_in_for])
    if community.nil?
      sign_out(user)
      flash[:notice] = nil
      flash[:danger] = 'Something went wrong trying to sign you in.'
      redirect_to root_path
      return
    end

    # Clear the cookie to prevent future issues
    cookies.delete(:signing_in_for)

    # We signed in for a different community, we need to send them back to the original community with encrypted
    # info about who signed in.
    encrypted_user_info = encrypt_user_info(user)
    redirect_to "//#{community.host}#{sign_in_return_from_base_path}?message=#{CGI.escape(encrypted_user_info)}",
                allow_other_host: true
  end

  # Encrypts user information for sending them to a different community.
  # @param user [User]
  def encrypt_user_info(user)
    len = ActiveSupport::MessageEncryptor.key_len - 1
    key = Rails.application.secrets.secret_key_base || Rails.application.credentials.secret_key_base
    crypt = ActiveSupport::MessageEncryptor.new(key[0..len])
    crypt.encrypt_and_sign(user.id, expires_in: 1.minute)
  end

  # Decrypts the user information when received at a different community.
  # @param data
  def decrypt_user_info(data)
    len = ActiveSupport::MessageEncryptor.key_len - 1
    key = Rails.application.secrets.secret_key_base || Rails.application.credentials.secret_key_base
    crypt = ActiveSupport::MessageEncryptor.new(key[0..len])
    crypt.decrypt_and_verify(data)
  end

  # @return [Community] the community to which the SSO is connected, and which must be used to sign in via.
  def base_community
    uri = URI.parse(Devise.saml_config.assertion_consumer_service_url)
    host = if uri.port != 80 && uri.port != 443 && !uri.port.nil?
             "#{uri.hostname}:#{uri.port}"
           else
             uri.hostname
           end
    Community.find_by(host: host) || Community.first
  rescue
    Community.first
  end
end
