class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator

  def users; end

  def subscriptions; end

  def posts; end
end
