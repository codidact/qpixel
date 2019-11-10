# Provides web and API actions that relate to flagging.
class FlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, only: [:resolve, :queue]

  # Authenticated API action. Creates a new flag with a reason, assigns it a post and a user, and puts it in the queue.
  def new
    @flag = Flag.new
    @flag.reason = params[:reason]
    @flag.post_id = params[:post_id]
    @flag.user = current_user
    if @flag.save
      render json: { status: 'success' }, status: 201
    else
      render json: { status: 'failed', message: 'Flag failed to save.' }, status: 500
    end
  end

  # Administrative web action. Provides a 'queue' of flags - i.e. a page containing any unresolved flags.
  def queue
    @flags = Flag.joins('left outer join flag_statuses on flags.id = flag_statuses.flag_id')
                 .where('flag_statuses.id is null').includes(:post).paginate(page: params[:page], per_page: 50)
  end

  # Administrative API action. Provides a route for moderators and administrators to resolve flags - that is, apply a
  # status to them.
  def resolve
    @flag = Flag.find params[:id]
    @flag.flag_status = FlagStatus.new(result: params[:result], message: params[:message])
    if @flag.save
      render json: { status: 'success' }
    else
      render json: { status: 'failed', message: 'Failed to save new status.' }, status: 500
    end
  end
end
