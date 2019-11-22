# Web controller. Provides actions for using voting features - essentially a stripped-down and renamed version of the
# standard resource set.
class VotesController < ApplicationController
  before_action :auth_for_voting

  # Authenticated web action. Casts a vote on behalf of a user. This is just about the most complex action in the application. Forbids
  # self-voting by default, but this is configurable by site setting. Also prevents duplicate votes of the same type by
  # the same user on one post; handles a user changing their vote, and deals with re-calculating post scores and user
  # reputation after the vote has been cast.
  #
  # Intended as an API action to be called from client-side JavaScript, rather than to be directly accessed - this
  # is only accessible on a POST route, and returns JSON for further client-side processing.
  def create
    post = Post.find(params[:post_id])

    if post.user == current_user && get_setting('AllowSelfVotes') != "true"
      render plain: "You may not vote on your own posts.", status: 403 and return
    end

    destroyed = post.votes.where(user: current_user).destroy_all
    vote = post.votes.create!(user: current_user, vote_type: params[:vote_type].to_i, recv_user: post.user)

    modified = destroyed.size > 0
    state = { status: (modified ? "modified" : "OK"), vote_id: vote.id, post_score: post.score }

    render json: state
  end

  # Authenticated web action. Removes a vote that has already been cast, and handles re-calculating post scores and user reputation.
  # Again, intended as an API action - is only accessible via DELETE requests, and returns JSON.
  def destroy
    vote = Vote.find params[:id]

    if vote.user != current_user
      render plain: "You are not authorized to remove this vote.", status: 403 and return
    end

    vote.destroy!

    render json: { status: "OK", post_score: vote.post.score }
  end

  private
    # A stripped-down <tt>:authenticate_user!</tt> that is used only for voting - we don't want to be redirected to
    # login if there isn't a user logged in, but we do want to prevent unauthenticated voting. Simply returns a 403
    # Forbidden with response text if the user is not logged in.
    def auth_for_voting
      if !user_signed_in?
        render plain: "You must be logged in to vote.", status: 403 and return
      end
    end

    # Given a vote and a post, calculates and applies the reputation changes necessitated by that vote. Handles
    # both the different vote and post types. The <tt>modifier</tt> parameter enables the <tt>create</tt> action to
    # reverse a vote (for the case where a user changes their vote) before applying a new vote; this is what keeps
    # the reputation bugs at bay.
    def calc_rep(vote, post, modifier)
      post_type = vote.post.post_type_id
      if vote.vote_type == 1
        if post_type == 2
          rep_add = modifier * get_setting('AnswerUpVoteRep').to_i
        else
          rep_add = modifier * get_setting('QuestionUpVoteRep').to_i
        end
      else
        if post_type == 2
          rep_add = modifier * get_setting('AnswerDownVoteRep').to_i
        else
          rep_add = modifier * get_setting('QuestionDownVoteRep').to_i
        end
      end
      post.user.reputation += rep_add
      if get_setting('RepNotificationsActive') == 'true'
        post.user.create_notification("#{rep_add} rep: #{(post_type == 1 ? post.title : post.parent.title)}", url_for(controller: :questions, action: :show, id: (post_type == 1 ? post.id : post.parent.id)))
      end
      post.user.save!
    end
end
