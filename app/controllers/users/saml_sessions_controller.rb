class Users::SamlSessionsController < Devise::SamlSessionsController
  # This method is almost the same code as the Users::SessionsController#create, and any changes
  # made here should probably also be applied over there.
  def create
    super do |user|
      if user.deleted?
        # The IDP already confirmed the sign in, so we can't fool the user any more that their credentials were incorrect.
        sign_out user
        flash[:notice] = nil
        flash[:danger] = 'We could not sign you in because of an issue with your account.'
        redirect_to root_path
        return
      end

      if user.community_user&.deleted?
        sign_out user
        flash[:notice] = nil
        flash[:danger] = 'Your profile on this community has been deleted.'
        redirect_to root_path
        return
      end

      if user.present? && user.enabled_2fa
        sign_out user
        case user.two_factor_method
        when 'app'
          id = user.id
          Users::SessionsController.first_factor << id
          redirect_to login_verify_2fa_path(uid: id)
          return
        when 'email'
          TwoFactorMailer.with(user: user, host: request.hostname).login_email.deliver_now
          flash[:notice] = nil
          flash[:info] = 'Please check your email inbox for a link to sign in.'
          redirect_to root_path
          return
        end
      end
    end
  end
end