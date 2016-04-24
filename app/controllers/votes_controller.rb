class VotesController < ApplicationController
  before_action :authenticate_user!

  def new
    post = (params[:post_type] == "a" ? Answer.find(params[:post_id]) : Question.find(params[:post_id]))
    existing = Vote.where(:post => post, :user => current_user)

    if existing.count > 0:
      if existing.first.vote_type == params[:vote_type].to_i
        render :plain => "You have already voted.", :status => 409 and return
      else
        # There's already a vote by this user on this post, so we may as well update that instead of removing it.
        vote = existing.first
        vote.vote_type = params[:vote_type].to_i
        vote.save!
        render :plain => "OK" and return
      end
    end

    vote = Vote.new
    vote.user = current_user
    vote.post = post
    vote.vote_type = params[:vote_type]
    vote.save!
    render :plain => "OK"
  end

  def destroy
    vote = Vote.find params[:id]

    if vote.user != current_user
      render :plain => "You are not authorized to remove this vote.", :status => 403 and return
    end

    vote.destroy
    render :plain => "OK"
  end
end
