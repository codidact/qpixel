class VotesController < ApplicationController
  before_action :auth_for_voting

  def create
    post = (params[:post_type] == "a" ? Answer.find(params[:post_id]) : Question.find(params[:post_id]))
    existing = Vote.where(:post => post, :user => current_user)

    if existing.count > 0
      if existing.first.vote_type == params[:vote_type].to_i
        render :plain => "You have already voted.", :status => 409 and return
      else
        # There's already a vote by this user on this post, so we may as well update that instead of removing it.
        vote = existing.first
        vote.vote_type = params[:vote_type].to_i
        vote.save!

        state = { :status => "OK", :vote_id => vote.id }
        render :json => state and return
      end
    end

    vote = Vote.new
    vote.user = current_user
    vote.post = post
    vote.vote_type = params[:vote_type]
    vote.save!

    state = { :status => "OK", :vote_id => vote.id }
    render :json => state and return
  end

  def destroy
    vote = Vote.find params[:id]

    if vote.user != current_user
      render :plain => "You are not authorized to remove this vote.", :status => 403 and return
    end

    vote.destroy
    render :plain => "OK"
  end

  private
    def auth_for_voting
      if !user_signed_in?
        render :plain => "You must be logged in to vote.", :status => 403 and return
      end
    end
end
