class DumpsController < ApplicationController
  before_action :authenticate_user!

  def index
    @latest = Dump.automatic.last
    @others = Dump.manual
  end
end
