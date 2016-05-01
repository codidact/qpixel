# Provides web and API actions that relate to flagging.
class FlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, :only => [:resolve]

  def new

  end

  def resolve

  end
end
