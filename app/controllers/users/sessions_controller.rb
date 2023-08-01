class Users::SessionsController < Devise::SessionsController
  protect_from_forgery except: [:create]

  mattr_accessor :first_factor, default: [], instance_writer: false, instance_reader: false

  # Any changes made here may also require changes to Users::SamlSessionsController#create.
  def create
    super do |user|
      return if post_sign_in(user)
    end
  end

  def verify_2fa; end

  def verify_code
    target_user = User.find params[:uid]

    if target_user.two_factor_token.blank?
      flash[:danger] = 'I have no idea how you got here, but something is very wrong.'
      redirect_to(root_path) && return
    end

    totp = ROTP::TOTP.new(target_user.two_factor_token)
    if totp.verify(params[:code], drift_ahead: 15, drift_behind: 15)
      if @@first_factor.include? params[:uid].to_i
        AuditLog.user_history(event_type: 'two_factor_success', related: target_user)
        @@first_factor.delete params[:uid].to_i
        flash[:info] = 'Signed in successfully.'
        sign_in_and_redirect User.find(params[:uid])
      else
        AuditLog.user_history(event_type: 'two_factor_fail', related: target_user, comment: 'first factor not present')
        flash[:danger] = "You haven't entered your password yet."
        if devise_sign_in_enabled?
          redirect_to new_session_path(target_user)
        else
          redirect_to new_saml_user_session_path(target_user)
        end
      end
    else
      AuditLog.user_history(event_type: 'two_factor_fail', related: target_user, comment: 'wrong code')
      flash[:danger] = "That's not the right code."
      redirect_to login_verify_2fa_path(uid: params[:uid])
    end
  end

  private

  # After a sign in, this method is called to check whether special conditions apply to the user.
  # The user may be signed out by this method.
  #
  # In general, this method should have similar behavior to the Users::SamlSessionsController#post_sign_in method.
  # If you make changes here, you may also have to update that method.
  # @param user [User]
  # @return [Boolean] false if the handling by the calling method should be stopped
  def post_sign_in(user)
    # For a deleted user (banished), tell them non-specifically that there was a mistake with their credentials.
    if user.deleted?
      sign_out user
      flash[:notice] = nil
      flash[:danger] = 'Invalid Email or password.'
      render :new
      return false
    end

    # If profile is deleted, the user was banished. Inform them and send them back to the sign in page.
    if user.community_user&.deleted?
      sign_out user
      flash[:notice] = nil
      flash[:danger] = 'Your profile on this community has been deleted.'
      render :new
      return false
    end

    # For users who are linked to an SSO Profile, disallow normal login and let them sign in through SSO instead.
    if user.sso_profile.present?
      sign_out user
      flash[:notice] = nil
      flash[:danger] = 'Please sign in using the Single Sign-On service of your institution.'
      redirect_to new_saml_user_session_path
      return false
    end

    # Enforce 2FA
    if user.enabled_2fa
      handle_2fa_login(user)
      return false
    end

    true
  end

  def handle_2fa_login(user)
    sign_out user
    case user.two_factor_method
    when 'app'
      id = user.id
      @@first_factor << id
      redirect_to login_verify_2fa_path(uid: id)
    when 'email'
      TwoFactorMailer.with(user: user, host: request.hostname).login_email.deliver_now
      flash[:notice] = nil
      flash[:info] = 'Please check your email inbox for a link to sign in.'
      redirect_to after_sign_in_path_for(user)
    end
  end
end
