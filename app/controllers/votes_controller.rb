class VotesController < ApplicationController
  before_action :auth_for_voting
  before_action :check_if_target_post_locked, only: [:create]
  before_action :check_if_parent_post_locked, only: [:destroy]

  def create
    post = Post.find(params[:post_id])

    if post.user == current_user && !SiteSetting['AllowSelfVotes']
      render(json: { status: 'failed', message: 'You may not vote on your own posts.' }, status: :forbidden) && return
    end

    recent_votes = Vote.where(created_at: 24.hours.ago..DateTime.now, user: current_user) \
                       .where.not(post: Post.includes(:parent).where(parents_posts: { user_id: current_user.id })).count
    max_votes_per_day = SiteSetting[current_user.privilege?('unrestricted') ? 'RL_Votes' : 'RL_NewUserVotes']

    if !post.parent&.user_id == current_user.id && recent_votes >= max_votes_per_day
      vote_limit_msg = "You have used your daily vote limit of #{recent_votes} votes." \
                       ' Come back tomorrow to continue voting. Votes on answers to own posts' \
                       ' are exempt.'

      AuditLog.rate_limit_log(event_type: 'vote', related: post, user: current_user,
                              comment: "limit: #{max_votes_per_day}\n\nvote:\n#{params[:vote_type].to_i}")

      render json: { status: 'failed', message: vote_limit_msg }, status: :forbidden
      return
    end

    destroyed = post.votes.where(user: current_user).destroy_all
    vote = post.votes.create(user: current_user, vote_type: params[:vote_type].to_i, recv_user: post.user)

    if vote.errors.any?
      render json: { status: 'failed', message: vote.errors.full_messages.join('. ') }, status: :forbidden
      return
    end

    Rails.cache.delete "community_user/#{current_user.community_user.id}/metric/V"
    ['s', 'v'].each do |key|
      Rails.cache.delete "community_user/#{post.user.community_user.id}/metric/#{key}"
    end

    AbilityQueue.add(post.user, "Vote Change on ##{post.id}")

    modified = !destroyed.empty?
    state = { status: (modified ? 'modified' : 'OK'), vote_id: vote.id, upvotes: post.upvote_count,
              downvotes: post.downvote_count }

    render json: state
  end

  def destroy
    vote = Vote.find params[:id]
    post = vote.post

    if vote.user != current_user
      render json: { status: 'failed', message: 'You are not authorized to remove this vote.' }, status: :forbidden
      return
    end

    if vote.destroy
      AbilityQueue.add(post.user, "Vote Change on ##{post.id}")
      render json: { status: 'OK', upvotes: post.upvote_count, downvotes: post.downvote_count }
    else
      render json: { status: 'failed', message: vote.errors.full_messages.join('. ') }, status: :forbidden
    end
  end

  private

  def auth_for_voting
    unless user_signed_in?
      render json: { status: 'failed', message: 'You must be logged in to vote.' }, status: :forbidden
    end
  end

  def check_if_target_post_locked
    check_if_locked(Post.find(params[:post_id]))
  end

  def check_if_parent_post_locked
    check_if_locked(Vote.find(params[:id]).post)
  end
end
