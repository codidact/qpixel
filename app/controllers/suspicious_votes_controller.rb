# Provides actions for admins to watch over voting patterns on the site.
class SuspiciousVotesController < ApplicationController
  before_action :verify_moderator

  def index
    @suspicious_votes = SuspiciousVote.pending
    @from_users = User.where(:id => @suspicious_votes.pluck(:from_user))
    @to_users = User.where(:id => @suspicious_votes.pluck(:to_user))
  end

  def user
    @from = SuspiciousVote.pending.where('from_user = ?', params[:id])
    @to = SuspiciousVote.pending.where('to_user = ?', params[:id])
  end
end
