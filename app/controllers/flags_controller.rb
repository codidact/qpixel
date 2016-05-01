# Provides web and API actions that relate to flagging.
class FlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, :only => [:resolve]

  # Authenticated API action. Creates a new flag with a reason, assigns it a post and a user, and puts it in the queue.
  def new

  end

  # Administrative web action. Provides a 'queue' of flags - i.e. a page containing any unresolved flags.
  def queue

  end

  # Administrative API action. Provides a route for moderators and administrators to resolve flags - that is, apply a
  # status to them.
  def resolve

  end
end
