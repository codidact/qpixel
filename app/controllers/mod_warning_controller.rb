class ModWarningController < ApplicationController
  before_action :verify_moderator, only: [:log, :new, :create]

  before_action :set_warning, only: [:current, :approve]
  before_action :set_user, only: [:log, :new, :create]

  def current
    render layout: 'without_sidebar'
  end

  def approve
    return not_found if @warning.suspension_active?

    if params[:approve_checkbox].nil?
      @failed_to_click_checkbox = true
      return render 'current', layout: 'without_sidebar'
    end

    @warning.update(active: false)
    redirect_to(root_path)
  end

  def log
    @warnings = ModWarning.where(community_user: @user.community_user).order(created_at: :desc).all
    render layout: 'without_sidebar'
  end

  def new
    @templates = WarningTemplate.where(active: true).all
    @prior_warning_count = ModWarning.where(community_user: @user.community_user).order(created_at: :desc).count
    @warning = ModWarning.new(author: current_user, community_user: @user.community_user)
    render layout: 'without_sidebar'
  end

  def create
    suspension_duration = params[:mod_warning][:suspension_duration].to_i

    suspension_duration = 1 if suspension_duration <= 0
    suspension_duration = 365 if suspension_duration > 365

    suspension_end = DateTime.now + suspension_duration.days

    is_suspension = !!params[:mod_warning][:is_suspension]

    @warning = ModWarning.new(author: current_user, community_user: @user.community_user,
                              body: params[:mod_warning][:body], is_suspension: is_suspension,
                              suspension_end: suspension_end, active: true)
    if @warning.save
      if is_suspension
        @user.community_user.update(is_suspended: is_suspension, suspension_end: suspension_end,
                     suspension_public_comment: params[:mod_warning][:suspension_public_notice])
      end

      redirect_to user_path(@user)
    else
      render :new
    end
  end

  private

  def set_warning
    @warning = ModWarning.where(community_user: current_user.community_user, active: true).last
    not_found if @warning.nil?
  end

  def set_user
    @user = user_scope.find_by(id: params[:user_id])
    not_found if @user.nil?
  end

  def user_scope
    User.joins(:community_user).includes(:community_user, :avatar_attachment)
  end
end
