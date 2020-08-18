# Web controller. Provides authenticated actions for use by administrators.
class AdminController < ApplicationController
  before_action :verify_admin
  before_action :verify_global_admin, only: [:admin_email, :send_admin_email, :hellban]

  def index; end

  def error_reports
    @reports = if params[:uuid].present?
                 ErrorLog.where(uuid: params[:uuid])
               elsif current_user.is_global_admin
                 ErrorLog.all
               else
                 ErrorLog.where(community: RequestContext.community)
               end.order(created_at: :desc).paginate(page: params[:page], per_page: 50)
  end

  def privileges
    @abilities = Ability.all
  end

  def show_privilege
    @ability = Ability.find_by internal_id: params[:name]
    respond_to do |format|
      format.json { render json: @ability }
    end
  end

  def update_privilege
    @privilege = Privilege.find_by name: params[:name]
    if params[:type] == 'post'
      pre = @privilege.post_score_threshold
      @privilege.update(post_score_threshold: params[:threshold])
    elsif params[:type] == 'edit'
      pre = @privilege.edit_score_threshold
      @privilege.update(edit_score_threshold: params[:threshold])
    elsif params[:type] == 'flag'
      pre = @privilege.flag_score_threshold
      @privilege.update(flag_score_threshold: params[:threshold])
    end && AuditLog.admin_audit(event_type: 'privilege_threshold_update', related: @privilege, user: current_user,
                           comment: "#{type} score\nfrom <<#{pre}>>\nto <<#{params[:threshold]}>>")
    render json: { status: 'OK', privilege: @privilege }, status: 202
  end

  def admin_email; end

  def send_admin_email
    Thread.new do
      AdminMailer.with(body_markdown: params[:body_markdown], subject: params[:subject]).to_moderators.deliver_now
    end
    AuditLog.admin_audit(event_type: 'send_admin_email', user: current_user,
                         comment: "Subject: #{params[:subject]}")
    flash[:success] = 'Your email is being sent.'
    redirect_to admin_path
  end

  def audit_log
    @logs = if current_user.is_global_admin
              AuditLog.unscoped.where.not(log_type: ['user_annotation', 'user_history'])
            else
              AuditLog.where.not(log_type: ['block_log', 'user_annotation', 'user_history'])
            end.user_sort({ term: params[:sort], default: :created_at },
                          age: :created_at, type: :log_type, event: :event_type,
                          related: Arel.sql('related_type DESC, related_id DESC'), user: :user_id)
            .paginate(page: params[:page], per_page: 100)
    render layout: 'without_sidebar'
  end

  def hellban
    @user = User.find params[:id]
    @user.block("user manually blocked by admin ##{current_user.id}")
    flash[:success] = 'User fed to STAT.'
    redirect_back fallback_location: admin_path
  end
end
