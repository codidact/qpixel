class ModWarningController < ApplicationController
  before_action :verify_moderator, only: [:log, :new, :create, :lift]
  before_action :verify_global_moderator, only: [:new_global, :create_global]
  before_action :set_warning, only: [:current, :approve]
  before_action :set_user, only: [:log, :new, :create, :lift, :new_global, :create_global]

  skip_before_action :check_if_warning_or_suspension_pending, only: [:current, :approve]

  def current
    render layout: 'without_sidebar'
  end

  def approve
    return not_found! if @warning.suspension_active?

    if params[:approve_checkbox].nil?
      @failed_to_click_checkbox = true
      return render 'current', layout: 'without_sidebar'
    end

    @warning.update(active: false, read: true)
    redirect_to(root_path)
  end

  def log
    warnings = ModWarning.to(@user)
    if current_user.is_global_moderator || current_user.is_global_admin
      warnings = warnings.or(ModWarning.where(user: @user, is_global: true))
    end
    warnings = warnings.all
                       .map { |w| { type: :warning, value: w } }

    user_followed_threads = ThreadFollower.where(user: @user).select(:comment_thread_id)
    messages = CommentThread.where(post: nil, is_private: true, id: user_followed_threads)
                            .all
                            .filter { |m| m.comments.first.user&.id != @user&.id }
                            .map { |m| { type: :message, value: m } }

    @entries = (warnings + messages).sort_by { |e| e[:value].created_at }.reverse
    render layout: 'without_sidebar'
  end

  def new
    @templates = WarningTemplate.where(active: true).all
    @prior_warning_count = ModWarning.to(@user).newest_first.count
    @warning = ModWarning.new(author: current_user, community_user: @user.community_user)
    render layout: 'without_sidebar'
  end

  def create
    suspension_duration = params[:mod_warning][:suspension_duration].to_i

    suspension_duration = 1 if suspension_duration <= 0
    suspension_duration = 365 if suspension_duration > 365

    suspension_end = DateTime.now + suspension_duration.days

    is_suspension = params[:mod_warning][:is_suspension] == 'true'

    @warning = ModWarning.new(author: current_user, community_user: @user.community_user,
                              body: params[:mod_warning][:body], is_suspension: is_suspension,
                              suspension_end: suspension_end, active: true, read: false, is_global: false)
    if @warning.save
      audit_warning('warning_create', @warning)

      if is_suspension
        @user.community_user.update(is_suspended: is_suspension, suspension_end: suspension_end,
                                    suspension_public_comment: params[:mod_warning][:suspension_public_notice])

        audit_warning('suspension_create', @warning)
      end

      redirect_to mod_user_path(@user)
    else
      render :new
    end
  end

  def new_global
    @warning = ModWarning.new(author: current_user, is_suspension: true)
    render layout: 'without_sidebar'
  end

  def create_global
    suspension_duration = params[:mod_warning][:suspension_duration].to_i

    suspension_duration = 1 if suspension_duration <= 0
    suspension_duration = 365 if suspension_duration > 365

    suspension_end = DateTime.now + suspension_duration.days

    @warning = ModWarning.new(author: current_user, user: @user,
                              body: params[:mod_warning][:body], is_suspension: true,
                              suspension_end: suspension_end, active: true, read: false,
                              is_global: true)
    if @warning.save
      @user.update(is_globally_suspended: true, global_suspension_end: suspension_end)

      redirect_to mod_user_path(@user)
    else
      render :new
    end
  end

  def lift
    @warning   = ModWarning.where(user: @user, is_global: true).active.last
    @warning ||= ModWarning.to(@user).active.last
    return not_found if @warning.nil?

    if @warning.is_global && !current_user.is_global_moderator && !current_user.is_global_admin
      flash[:error] = 'A network-wide suspension has been applied which may only be lifted by global moderators. ' \
                      'Community-wide suspensions which have been imposed before that global suspension cannot be ' \
                      'lifted at this time (which is probably why you are seeing this error).'
      redirect_to mod_warning_log_path(@user)
    end

    @warning.update(active: false, read: false)
    if @warning.is_global
      @user.update is_globally_suspended: false, global_suspension_end: nil
    else
      @user.community_user.update is_suspended: false, suspension_public_comment: nil, suspension_end: nil
    end

    audit_warning('warning_lift', @warning)

    if @warning.suspension?
      audit_warning('suspension_lift', @warning)
    end

    flash[:success] = 'The warning or suspension has been lifted. Please consider adding an annotation ' \
                      'explaining your reasons.'
    redirect_to mod_warning_log_path(@user)
  end

  private

  def set_warning
    @warning   = ModWarning.where(user: current_user, active: true, is_global: true).last
    @warning ||= ModWarning.to(current_user).active.last
    not_found if @warning.nil?
  end

  def set_user
    @user = user_scope.find_by(id: params[:user_id])
    not_found! if @user.nil?
  end

  def user_scope
    User.joins(:community_user).includes(:community_user, :avatar_attachment)
  end

  # Adds an audit log for a given mod warning
  # @param event_type [String] type of the event
  # @param warning [ModWarning] warning to audit
  def audit_warning(event_type, warning)
    AuditLog.moderator_audit(event_type: event_type,
                             related: warning, user: current_user,
                             comment: "<<Warning #{warning.attributes_print} >>")
  end
end
