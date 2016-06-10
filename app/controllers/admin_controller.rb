# Web controller. Provides authenticated actions for use by administrators.
class AdminController < ApplicationController
  before_action :verify_admin

  # Administrative web action. No dynamic content - this is purely representative of the existence of a (relatively)
  # static view for this path.
  def index
  end
end
