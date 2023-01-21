class Users::RegistrationsController < Devise::RegistrationsController
  protected

  before_action :check_sso, only: :update

  def after_update_path_for(resource)
    edit_user_registration_path(resource)
  end

  def check_sso
    if current_user && current_user.sso_profile.present?
      flash['danger'] = 'You sign in with SSO, so updating your email/password is not possible.'
      redirect_to edit_user_registration_path
    end
  end
end
