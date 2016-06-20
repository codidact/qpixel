# Provides actions for admins to watch over voting patterns on the site.
class SuspiciousVotesController < ApplicationController
  before_action :verify_moderator

  def index
    @suspicious_votes = SuspiciousVote.pending
    @from_users = User.where(:id => @suspicious_votes.pluck(:from_user)).map { |u| [u.id, u] }.to_h
    @to_users = User.where(:id => @suspicious_votes.pluck(:to_user)).map { |u| [u.id, u] }.to_h
  end

  def user
    @user = User.find params[:id]
    @from = SuspiciousVote.pending.where('from_user = ?', params[:id])
    @to = SuspiciousVote.pending.where('to_user = ?', params[:id])
    @from_users = User.where(:id => @from.pluck(:from_user)).map { |u| [u.id, u] }.to_h
    @to_users = User.where(:id => @to.pluck(:to_user).map { |u| [u.id, u] }.to_h)
  end

  def investigated
    @sv = SuspiciousVote.find params[:id]
    @sv.was_investigated = true
    @sv.investigated_at = Time.now
    @sv.investigated_by = current_user.id
    if @sv.save
      render :json => { :status => 'success' }
    else
      render :json => { :status => 'failed' }, :status => 500
    end
  end
end
