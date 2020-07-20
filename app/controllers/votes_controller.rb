# Web controller. Provides actions for using voting features - essentially a stripped-down and renamed version of the
# standard resource set.
class VotesController < ApplicationController
  before_action :auth_for_voting

  def create
    post = Post.find(params[:post_id])

    if post.user == current_user && !SiteSetting['AllowSelfVotes']
      render(json: { status: 'failed', message: 'You may not vote on your own posts.' }, status: 403) && return
    end

    recent_votes = Vote.where(created_at: 24.hours.ago..Time.now, user: current_user).count
    max_votes_per_day = SiteSetting['FreeVotes'] + (@current_user.reputation - SiteSetting['NewUserInitialRep'])

    if recent_votes >= max_votes_per_day
      vote_limit_msg = 'You have used your daily vote limit: ' + recent_votes.to_s + '/' + max_votes_per_day.to_s
      render json: { status: 'failed', message: vote_limit_msg }, status: 403
      return
    end

    destroyed = post.votes.where(user: current_user).destroy_all
    vote = post.votes.create(user: current_user, vote_type: params[:vote_type].to_i, recv_user: post.user)

    if vote.errors.any?
      render json: { status: 'failed', message: vote.errors.full_messages.join('. ') }, status: 403
      return
    end

    modified = !destroyed.empty?
    state = { status: (modified ? 'modified' : 'OK'), vote_id: vote.id, upvotes: post.upvote_count,
              downvotes: post.downvote_count }

    render json: state
  end

  def destroy
    vote = Vote.find params[:id]
    post = vote.post

    if vote.user != current_user
      render(json: { status: 'failed', message: 'You are not authorized to remove this vote.' }, status: 403) && return
    end

    if vote.destroy
      render json: { status: 'OK', upvotes: post.upvote_count, downvotes: post.downvote_count }
    else
      render json: { status: 'failed', message: vote.errors.full_messages.join('. ') }, status: 403
    end
  end

  private

  def auth_for_voting
    unless user_signed_in?
      render json: { status: 'failed', message: 'You must be logged in to vote.' }, status: 403
    end
  end
end
