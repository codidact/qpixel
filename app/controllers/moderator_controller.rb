# Web controller. Provides authenticated actions for use by moderators. A lot of the stuff in here, and hence a lot of
# the tools, are rather repetitive.
class ModeratorController < ApplicationController
  before_action :verify_moderator, except: [:nominate_promotion, :promotions, :remove_promotion]
  before_action :authenticate_user!, only: [:nominate_promotion, :promotions, :remove_promotion]
  before_action :set_post, only: [:nominate_promotion, :remove_promotion]
  before_action :unless_locked, only: [:nominate_promotion, :remove_promotion]

  def index; end

  def recently_deleted_posts
    @posts = Post.unscoped.where(community: @community, deleted: true).order('deleted_at DESC')
                 .paginate(page: params[:page], per_page: 50)
  end

  def recent_comments
    @comments = Comment.all.includes(:user, :post).order(created_at: :desc).paginate(page: params[:page], per_page: 50)
  end

  def nominate_promotion
    return not_found(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'
    return not_found(errors: ['unavailable_for_type']) unless top_level_post_types.include? @post.post_type_id

    PostHistory.nominated_for_promotion(@post, current_user)
    nominations = helpers.promoted_posts
    nominations.merge!(@post.id => DateTime.now.to_i)
    nominations.select! { |_k, v| DateTime.now.to_i - v <= 3600 * 24 * 28 }
    RequestContext.redis.set 'network/promoted_posts', JSON.dump(nominations)
    render json: { status: 'success', success: true }
  end

  def promotions
    return not_found(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'

    # This is network-wide, but the Post selection will default to current site only, so not a problem.
    @promotions = helpers.promoted_posts
    @posts = Post.where(id: @promotions.keys)
  end

  def remove_promotion
    return not_found(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'

    promotions = helpers.promoted_posts
    return not_found(errors: ['not_promoted']) unless promotions.keys.include? @post.id.to_s

    promotions = promotions.reject { |k, _v| k == @post.id.to_s }
    RequestContext.redis.set 'network/promoted_posts', JSON.dump(promotions)
    render json: { status: 'success', success: true }
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def unless_locked
    check_if_locked(@post)
  end
end
