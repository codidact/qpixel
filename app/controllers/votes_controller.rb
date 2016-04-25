class VotesController < ApplicationController
  before_action :auth_for_voting

  def create
    post = (params[:post_type] == "a" ? Answer.find(params[:post_id]) : Question.find(params[:post_id]))
    vote = post.votes.find_or_initialize_by(:user => current_user)

    if post.user == current_user
      (render :plain => "You may not vote on your own posts.", :status => 403 and return) unless get_setting('AllowSelfVotes') == "true"
    end

    if vote.vote_type == params[:vote_type].to_i
      # already voted
      render :plain => "You have already voted.", :status => 409 and return
    else
      modified = false
      if vote.vote_type
        # modify vote
        modified = true
        calc_rep(vote, post, -1)
      end
      vote.vote_type = params[:vote_type].to_i
      vote.save!
      state = { :status => (modified ? "modified" : "OK"), :vote_id => vote.id }
    end

    post.score = post.votes.sum(:vote_type)
    post.save!
    state[:post_score] = post.score

    calc_rep(vote, post, 1)

    render :json => state
  end

  def destroy
    vote = Vote.find params[:id]

    if vote.user != current_user
      render :plain => "You are not authorized to remove this vote.", :status => 403 and return
    end

    if vote.vote_type == 1
      if vote.post_type == 'Answer'
        vote.post.user.reputation -= get_setting('AnswerUpVoteRep').to_i or 0
      else
        vote.post.user.reputation -= get_setting('QuestionUpVoteRep').to_i or 0
      end
    else
      if vote.post_type == 'Answer'
        vote.post.user.reputation -= get_setting('AnswerDownVoteRep').to_i or 0
      else
        vote.post.user.reputation -= get_setting('QuestionDownVoteRep').to_i or 0
      end
    end
    vote.destroy

    vote.post.score = vote.post.votes.sum(:vote_type)
    vote.post.save!
    vote.post.user.save!

    render :json => { :status => "OK", :post_score => vote.post.score }
  end

  private
    def auth_for_voting
      if !user_signed_in?
        render :plain => "You must be logged in to vote.", :status => 403 and return
      end
    end

    def calc_rep(vote, post, modifier)
      if vote.vote_type == 1
        if vote.post_type == 'Answer'
          post.user.reputation += modifier * get_setting('AnswerUpVoteRep').to_i
        else
          post.user.reputation += modifier * get_setting('QuestionUpVoteRep').to_i
        end
      else
        if vote.post_type == 'Answer'
          post.user.reputation += modifier * get_setting('AnswerDownVoteRep').to_i
        else
          post.user.reputation += modifier * get_setting('QuestionDownVoteRep').to_i
        end
      end
      post.user.save!
    end
end
