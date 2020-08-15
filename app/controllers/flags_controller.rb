# Provides web and API actions that relate to flagging.
class FlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :flag_verify, only: [:resolve, :queue]

  def new
    type = if params[:flag_type].present?
             PostFlagType.find params[:flag_type]
           end

    @flag = Flag.new(post_flag_type: type, reason: params[:reason], post_id: params[:post_id], user: current_user)
    if @flag.save
      render json: { status: 'success' }, status: 201
    else
      render json: { status: 'failed', message: 'Flag failed to save.' }, status: 500
    end
  end

  def history
    @user = User.find(params[:id])
    unless @user == current_user || (current_user.is_admin || current_user.is_mod)
      not_found
      return
    end
    @flags = @user.flags.includes(:post).order(id: :desc).paginate(page: params[:page], per_page: 50)
    @statuses = @flags.group(:status).count(:status)
  end

  def queue
    @flags = Flag.unhandled.includes(:post).paginate(page: params[:page], per_page: 20)
  end

  def resolve
    if @flag.update(status: params[:result], message: params[:message], handled_by: current_user,
                    handled_at: DateTime.now)
      render json: { status: 'success' }
    else
      render json: { status: 'failed', message: 'Failed to save new status.' }, status: 500
    end
  end

  private

  def flag_verify
    @flag = Flag.find params[:id]
    return false if current_user.nil?

    type = @flag.post_flag_type
    unless current_user.is_moderator
      return not_found unless current_user.privilege? 'flag_curate'
      return not_found if type.nil? || type.confidential
    end
  end
end
