class Users::RegistrationsController < Devise::RegistrationsController
  layout 'without_sidebar', only: :edit

  before_action :check_sso, only: :update
  before_action :authenticate_user!, only: [:delete, :do_delete]
  before_action :require_sudo, only: [:delete, :do_delete]

  def create
    super do |user|
      unless user.errors.any?
        rate_limit = AppConfig.server_settings['registration_rate_limit']
        ip_list = [user.current_sign_in_ip, request.remote_ip].compact
        previous_ip_users = User.where(current_sign_in_ip: ip_list).or(User.where(last_sign_in_ip: ip_list))
                                .where(created_at: rate_limit.seconds.ago..DateTime.now)
                                .where.not(id: user.id)
        if previous_ip_users.empty?
          user.send_welcome_tour_message
          user.ensure_websites
        else
          user.delete
          flash[:danger] = 'You cannot create an account right now because of the volume of accounts originating ' \
                           'from your network. Try again later.'
        end
      end
    end
  end

  def delete
    @user = current_user
  end

  def do_delete
    @user = current_user
    if @user.admin?
      @user.errors.add(:base, I18n.t('users.errors.no_admin_self_delete'))
      render :delete
    elsif @user.moderator?
      @user.errors.add(:base, I18n.t('users.errors.no_mod_self_delete'))
      render :delete
    elsif @user.enabled_2fa
      @user.errors.add(:base, I18n.t('users.errors.no_2fa_self_delete'))
      render :delete
    elsif params[:username] != @user.username
      @user.errors.add(:base, I18n.t('users.errors.self_delete_wrong_username'))
      render :delete
    else
      UserMailer.with(user: @user, host: RequestContext.community.host, community: RequestContext.community)
                .deletion_confirmation.deliver_later
      @user.do_soft_delete(@user)
      flash[:info] = 'Sorry to see you go!'
      redirect_to root_path
    end
  end

  protected

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
