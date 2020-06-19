class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator

  def users
    @users = User.joins(:community_users).where(community_users: { community_id: RequestContext.community_id })
                 .where("users.email NOT LIKE '%localhost'")
                 .where('users.created_at >= ?', 1.year.ago).group_by_week(:created_at).count
  end

  def subscriptions; end

  def posts; end
end
