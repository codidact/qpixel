# Web controller. Provides authenticated actions for use by moderators. A lot of the stuff in here, and hence a lot of
# the tools, are rather repetitive.
class ModeratorController < ApplicationController
  before_action :verify_can_see_deleted_posts, only: [:recently_deleted_posts]
  before_action :verify_moderator,
                except: [:nominate_promotion, :promotions, :remove_promotion, :recently_deleted_posts]
  before_action :authenticate_user!,
                only: [:nominate_promotion, :promotions, :remove_promotion, :recently_deleted_posts]
  before_action :set_post, only: [:nominate_promotion, :remove_promotion]
  before_action :unless_locked, only: [:nominate_promotion, :remove_promotion]

  def index; end

  def recently_deleted_posts
    @posts = Post.unscoped.on(@community).deleted.order(deleted_at: :desc).paginate(page: params[:page], per_page: 50)
  end

  def recent_comments
    @comments = Comment.all.includes(:user, :post).newest_first.paginate(page: params[:page], per_page: 50)
  end

  def nominate_promotion
    return not_found!(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'
    return not_found!(errors: ['unavailable_for_type']) unless top_level_post_types.include? @post.post_type_id

    PostHistory.nominated_for_promotion(@post, current_user)
    nominations = helpers.promoted_posts
    nominations.merge!(@post.id => DateTime.now.to_i)
    nominations.select! { |_k, v| DateTime.now.to_i - v <= 3600 * 24 * 28 }
    RequestContext.redis.set 'network/promoted_posts', JSON.dump(nominations)
    render json: { status: 'success', success: true }
  end

  def promotions
    return not_found!(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'

    # This is network-wide, but the Post selection will default to current site only, so not a problem.
    @promotions = helpers.promoted_posts
    @posts = Post.where(id: @promotions.keys)
  end

  def remove_promotion
    return not_found!(errors: ['no_privilege']) unless current_user.privilege? 'flag_curate'

    promotions = helpers.promoted_posts
    return not_found!(errors: ['not_promoted']) unless promotions.keys.include? @post.id.to_s

    promotions = promotions.reject { |k, _v| k == @post.id.to_s }
    RequestContext.redis.set 'network/promoted_posts', JSON.dump(promotions)
    render json: { status: 'success', success: true }
  end

  VoteData = Struct.new(:cast, :received, keyword_init: true)
  VoteSummary = Struct.new(:breakdown, :types, :total, keyword_init: true)

  def user_vote_summary
    @user = User.find params[:id]
    @users = User.where(id: Vote.by(@user).select(:recv_user_id).distinct)
                 .or(User.where(id: Vote.for(@user).select(:user_id).distinct))
    @vote_data = VoteData.new(
      cast: VoteSummary.new(
        breakdown: Vote.by(@user).group(:recv_user_id, :vote_type).count,
        types: Vote.by(@user).group(:vote_type).count,
        total: Vote.by(@user).count
      ),
      received: VoteSummary.new(
        breakdown: Vote.for(@user).group(:user_id, :vote_type).count,
        types: Vote.for(@user).group(:vote_type).count,
        total: Vote.for(@user).count
      )
    )
  end

  def spammy_users
    script = File.read(Rails.root.join('db/scripts/potential_spam_profiles.sql'))
    script = script.gsub('$HOURS', '5208') # 31 days
    user_ids = ApplicationRecord.connection.execute(script).to_a.flatten
    @users = User.where(id: user_ids).limit(20)
  end

  def handle_spammy_users
    spam = User.where(id: params[:spam_ids])
    spam.each do |user|
      user.block('Profile spam', length: 10.years, automatic: false)
      user.do_soft_delete(current_user)
    end
    flash[:success] = "#{spam.size} users blocked and deleted."
    redirect_to mod_spammers_path
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def unless_locked
    check_if_locked(@post)
  end

  def verify_can_see_deleted_posts
    if !user_signed_in? || !current_user.can_see_deleted_posts?
      render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      return false
    end
    true
  end
end
