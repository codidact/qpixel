class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |user|
      unless user.errors.any?
        rate_limit = AppConfig.server_settings['registration_rate_limit']
        ip_list = [user.current_sign_in_ip, request.remote_ip].compact
        previous_ip_users = User.where(current_sign_in_ip: ip_list).or(User.where(last_sign_in_ip: ip_list))
                                .where(created_at: rate_limit.seconds.ago..DateTime.now)
                                .where.not(id: user.id)
        if previous_ip_users.size.zero?
          user.send_welcome_tour_message
          user.ensure_websites
        else
          user.delete
          flash[:danger] = 'You cannot create an account right now because of the volume of accounts originating from ' \
                           'your network. Try again later.'
        end
      end
    end
  end

  protected

  layout 'without_sidebar', only: :edit

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
