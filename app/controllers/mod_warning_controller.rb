class ModWarningController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_moderator, only: [:log, :new, :create]

  before_action :set_warning, only: [:current, :approve]
  before_action :set_user, only: [:log, :new, :create]

  def current
    render layout: 'without_sidebar'
  end

  def approve
    return not_found if @warning.is_suspension

    if params[:approve_checkbox].nil?
      @failed_to_click_checkbox = true
      return render 'current', layout: 'without_sidebar'
    end
    
    @warning.update(active: false)
    redirect_to(root_path)
  end

  def log
    @warnings = ModWarning.where(community_user: @user.community_user).all
  end

  def new
  end

  def create
  end

  private

  def set_warning
    @warning = ModWarning.where(community_user: current_user.community_user, active: true).last
    @warning_message_html = helpers.render_markdown(@warning.body)
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
