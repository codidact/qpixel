class CustomSessionsController < Devise::SessionsController
  protect_from_forgery except: [:create]

  @@first_factor = []

  def new
    super
  end

  def create
    super do |user|
      if user.present? && user.enabled_2fa
        sign_out user
        if user.two_factor_method == 'app'
          id = user.id
          @@first_factor << id
          redirect_to login_verify_2fa_path(uid: id)
          return
        elsif user.two_factor_method == 'email'
          TwoFactorMailer.with(user: user, host: request.hostname).login_email.deliver_now
          flash[:notice] = nil
          flash[:info] = 'Please check your email inbox for a link to sign in.'
          redirect_to root_path
          return
        end
      end
    end
  end

  def destroy
    super
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
        @@first_factor.delete params[:uid].to_i
        flash[:info] = 'Signed in successfully.'
        sign_in_and_redirect User.find(params[:uid])
      else
        flash[:danger] = "You haven't entered your password yet."
        redirect_to new_session_path(target_user)
      end
    else
      flash[:danger] = "That's not the right code."
      redirect_to login_verify_2fa_path(uid: params[:uid])
    end
  end
end
