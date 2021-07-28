class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    RequestContext.redis.hset 'network/community_registrations', @user.email, RequestContext.community_id
  end
end
