# Provides web and API actions that relate to flagging.
class FlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, only: [:queue, :handled, :escalate]
  before_action :verify_admin, only: [:escalated_queue]
  before_action :flag_verify, only: [:resolve]

  def new
    type = if params[:flag_type].present?
             PostFlagType.find params[:flag_type]
           end

    recent_flags = Flag.by(current_user).recent.count
    max_flags_per_day = SiteSetting[current_user.privilege?('unrestricted') ? 'RL_Flags' : 'RL_NewUserFlags']

    if recent_flags >= max_flags_per_day
      flag_limit_msg = I18n.t('flags.errors.rate_limited', count: max_flags_per_day)

      AuditLog.rate_limit_log(event_type: 'flag', related: Post.find(params[:post_id]), user: current_user,
                              comment: "limit: #{max_flags_per_day}\n\ntype:#{type}\ncomment:\n#{params[:reason].to_i}")

      render json: { status: 'failed', message: flag_limit_msg }, status: :forbidden
      return
    end

    if type&.name == "needs author's attention"
      create_as_feedback_comment Post.find(params[:post_id]), current_user, params[:reason]
      render json: { status: 'success' }, status: :created
      return
    end

    @flag = Flag.new(post_flag_type: type, reason: params[:reason], post_id: params[:post_id],
                     post_type: params[:post_type], user: current_user)
    if @flag.save
      render json: { status: 'success' }, status: :created
    else
      render json: { status: 'failed', message: 'Flag failed to save.' }, status: :bad_request
    end
  end

  def history
    @user = helpers.user_with_me params[:id]
    unless @user == current_user || current_user.at_least_moderator?
      not_found!
      return
    end
    @flags = @user.flags.includes(:post).order(id: :desc).paginate(page: params[:page], per_page: 50)
    @statuses = @flags.group(:status).count(:status)
  end

  def queue
    @flags = Flag.unhandled.includes(:post, :user).paginate(page: params[:page], per_page: 20)
  end

  def handled
    @flags = Flag.handled.includes(:post, :user, :handled_by).newest_first
                 .paginate(page: params[:page], per_page: 50)
  end

  def resolve
    if @flag.update(status: params[:result], message: params[:message], handled_by: current_user,
                    handled_at: DateTime.now)
      AbilityQueue.add(@flag.user, "Flag Handled ##{@flag.id}")
      render json: { status: 'success' }
    else
      render json: { status: 'failed', message: 'Failed to save new status.' }, status: :internal_server_error
    end
  end

  def escalate
    @flag = Flag.find params[:id]
    @flag.update(escalated: true, escalated_by: current_user, escalated_at: DateTime.now,
                 escalation_comment: params[:comment])
    FlagMailer.with(flag: @flag).flag_escalated.deliver_now
    render json: { status: 'success' }
  end

  def escalated_queue
    @flags = Flag.unhandled.includes(:post, :user).where(escalated: true).paginate(page: params[:page], per_page: 20)
    render :queue
  end

  private

  def flag_verify
    @flag = Flag.find params[:id]

    return false if current_user.nil?

    type = @flag.post_flag_type

    unless current_user.at_least_moderator?
      return not_found! unless current_user.privilege? 'flag_curate'
      return not_found! if type.nil? || type.confidential

      not_found! if current_user.same_as?(@flag.user)
    end
  end

  def create_as_feedback_comment(post, user, content)
    thread = post.comment_threads.find_or_create_by(title: 'Post Feedback', deleted: false)
    comment = nil
    ActiveRecord::Base.transaction do
      comment = thread.comments.create!(user: user, post: post, comment_thread: thread, content: content)
      post.user.create_notification("New feedback on #{comment.root.title}",
                                    comment_thread_path(thread, anchor: "comment-#{comment.id}"))
    end
    comment
  end
end
