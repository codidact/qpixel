# Provides actions for admins to watch over voting patterns on the site.
class SuspiciousVotesController < ApplicationController
  before_action :verify_moderator

  def index
    @suspicious_votes = SuspiciousVote.pending
  end

  def user
    @user = User.find params[:id]
    @from = SuspiciousVote.pending.where(from_user: @user)
    @to = SuspiciousVote.pending.where(to_user: @user)
  end

  def investigated
    @sv = SuspiciousVote.find params[:id]
    @sv.was_investigated = true
    @sv.investigated_at = DateTime.now
    @sv.investigated_by = current_user.id
    if @sv.save
      render json: { status: 'success' }
    else
      render json: { status: 'failed' }, status: :internal_server_error
    end
  end
end
