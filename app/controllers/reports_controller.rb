class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, except: [:users_global, :subs_global, :posts_global]
  before_action :verify_global_moderator, only: [:users_global, :subs_global, :posts_global]

  def users
    @users_all = User.joins(:community_users).where(community_users: { community_id: RequestContext.community_id })
                     .where('users.created_at >= ?', 1.year.ago)
    @users = @users_all.where("users.email NOT LIKE '%localhost'")
    @users_se = @users_all.where("users.email LIKE '%localhost'")
  end

  def subscriptions
    @subs = Subscription.where('created_at >= ?', 1.year.ago)
    @types = Subscription.all.group(:type).count
  end

  def posts
    @questions = Question.where('created_at >= ?', 1.year.ago).undeleted
    @answers = Answer.where('created_at >= ?', 1.year.ago).undeleted
    @comments = Comment.where('created_at >= ?', 1.year.ago).undeleted
    @this_month = Post.where('created_at >= ?', 1.month.ago).undeleted
  end

  def users_global
    @users_all = User.where('users.created_at >= ?', 1.year.ago)
    @users = @users_all.where("users.email NOT LIKE '%localhost'")
    @users_se = @users_all.where("users.email LIKE '%localhost'")
    render :users
  end

  def subs_global
    @subs = Subscription.unscoped.where('created_at >= ?', 1.year.ago)
    @types = Subscription.unscoped.all.group(:type).count
    render :subscriptions
  end

  def posts_global
    @questions = Post.unscoped.where(post_type_id: Question.post_type_id).where('created_at >= ?', 1.year.ago).undeleted
    @answers = Post.unscoped.where(post_type_id: Answer.post_type_id).where('created_at >= ?', 1.year.ago).undeleted
    @comments = Comment.unscoped.where('created_at >= ?', 1.year.ago).undeleted
    @this_month = Post.unscoped.where('created_at >= ?', 1.month.ago).undeleted
    render :posts
  end
end
