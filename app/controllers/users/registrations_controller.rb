class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    RequestContext.redis.hset 'network/community_registrations', @user.email, RequestContext.community_id
  end

  protected

  def after_update_path_for(resource)
    edit_user_registration_path(resource)
  end
end
