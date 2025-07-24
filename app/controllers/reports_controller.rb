class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, except: [:users_global, :subs_global, :posts_global]
  before_action :verify_global_moderator, only: [:users_global, :subs_global, :posts_global]

  def users
    @users_all = User.joins(:community_users)
                     .where(community_users: { community_id: RequestContext.community_id })
                     .recent(1.year.ago)
    @users = @users_all.where("users.email NOT LIKE '%localhost'")
    @users_se = @users_all.where("users.email LIKE '%localhost'")
  end

  def subscriptions
    @subs = Subscription.recent(1.year.ago)
    @types = Subscription.all.group(:type).count
  end

  def posts
    @questions = Question.recent(1.year.ago).undeleted
    @answers = Answer.recent(1.year.ago).undeleted
    @comments = Comment.recent(1.year.ago).undeleted
    @this_month = Post.recent(1.month.ago).undeleted
    @categories = Category.where('IFNULL(categories.min_view_trust_level, 0) <= ?', current_user&.trust_level || 0)
                          .order(:sequence)
    @posts_categories = Post.in(@categories).group(:category_id).count
  end

  def reactions
    @reaction_types = ReactionType.active
    @reactions = Reaction.all
    @users = Reaction.select(:user_id).distinct
  end

  def users_global
    @users_all = User.recent(1.year.ago)
    @users = @users_all.where("users.email NOT LIKE '%localhost'")
    @users_se = @users_all.where("users.email LIKE '%localhost'")
    render :users
  end

  def subs_global
    @subs = Subscription.unscoped.recent(1.year.ago)
    @types = Subscription.unscoped.all.group(:type).count
    render :subscriptions
  end

  def posts_global
    @questions = Post.unscoped.where(post_type_id: Question.post_type_id).recent(1.year.ago).undeleted
    @answers = Post.unscoped.where(post_type_id: Answer.post_type_id).recent(1.year.ago).undeleted
    @comments = Comment.unscoped.recent(1.year.ago).undeleted
    @this_month = Post.unscoped.recent(1.month.ago).undeleted
    @categories = Category.unscoped
                          .where('IFNULL(categories.min_view_trust_level, 0) <= ?', current_user&.trust_level || 0)
                          .includes(:community).order(:community_id, :sequence)
    @posts_categories = Post.unscoped.in(@categories).group(:category_id).count
    @global = true
    render :posts
  end
end
