# Web controller. Provides actions for using voting features - essentially a stripped-down and renamed version of the
# standard resource set.
class VotesController < ApplicationController
  before_action :auth_for_voting

  def create
    post = Post.find(params[:post_id])

    if post.user == current_user && !SiteSetting['AllowSelfVotes']
      render plain: "You may not vote on your own posts.", status: 403 and return
    end

    destroyed = post.votes.where(user: current_user).destroy_all
    vote = post.votes.create!(user: current_user, vote_type: params[:vote_type].to_i, recv_user: post.user)

    modified = destroyed.size > 0
    state = {status: (modified ? "modified" : "OK"), vote_id: vote.id, post_score: post.score}

    render json: state
  end

  def destroy
    vote = Vote.find params[:id]

    if vote.user != current_user
      render plain: "You are not authorized to remove this vote.", status: 403 and return
    end

    vote.destroy!

    render json: {status: "OK", post_score: vote.post.score}
  end

  private

  def auth_for_voting
    unless user_signed_in?
      render plain: "You must be logged in to vote.", status: 403
    end
  end
end
