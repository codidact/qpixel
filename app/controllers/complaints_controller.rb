class ComplaintsController < ApplicationController
  before_action :set_complaint, only: [:show, :comment, :self_assign, :update_status]
  before_action :access_check, only: [:show, :comment]
  before_action :write_access_check, only: [:self_assign, :update_status]
  before_action :verify_staff, only: [:reports, :reporting]

  def index
    render layout: 'without_sidebar'
  end

  def report
    @report_types = AppConfig.safety_center['report_types'].select { |_k, t| t['enabled'] }
    @content_types = AppConfig.safety_center['content_types']
    @complaint = Complaint.new
    @errors = []
    render layout: 'without_sidebar'
  end

  def create
    @report_types = AppConfig.safety_center['report_types'].select { |_k, t| t['enabled'] }
    @content_types = AppConfig.safety_center['content_types']

    complaint_params = params.permit(:report_type, :reported_url, :content_type, :user_wants_updates)
    comment_params = params.permit(:content)
    if user_signed_in?
      complaint_params.merge!(user: current_user, email: current_user.email)
      comment_params.merge!(user: current_user)
    else
      complaint_params.merge!(email: params[:email])
    end

    @complaint = Complaint.new(complaint_params)
    @comment = ComplaintComment.new(comment_params.merge(internal: false))

    begin
      Complaint.transaction do
        @complaint.save!
        @comment.complaint = @complaint
        @comment.save!
      end

      redirect_to complaint_path(@complaint.access_token)
    rescue ActiveRecord::RecordInvalid
      @errors = @complaint.errors.full_messages + @comment.errors.full_messages
      render :report, status: :bad_request, layout: 'without_sidebar'
    end
  end

  def show
    @report_type = AppConfig.safety_center['report_types'][@complaint.report_type]
    @content_type = AppConfig.safety_center['content_types'][@complaint.content_type]
    @status = AppConfig.safety_center['statuses'][@complaint.status]
    render layout: 'without_sidebar'
  end

  def comment
    permitted = [:content]
    if user_signed_in? && current_user.staff?
      permitted << :internal
    end

    default_params = { user: current_user, internal: false, complaint: @complaint }
    comment_params = default_params.merge(params.permit(*permitted).to_h)

    @comment = ComplaintComment.new(comment_params)
    if @comment.save
      respond_to do |format|
        format.json do
          render json: { status: 'success',
                         comment: render_to_string(partial: 'comment', locals: { comment: @comment },
                                                   formats: [:html]),
                         can_add_more: @complaint.can_add_more_comments?(current_user) }
        end
        format.html do
          flash[:success] = 'Your reply was saved.'
          redirect_to complaint_path(@complaint.access_token)
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { status: 'failed', message: "Couldn't save your reply", errors: @comment.errors.full_messages },
                 status: :bad_request
        end
        format.html do
          flash[:danger] = "Couldn't save your reply: #{@comment.errors.full_messages.join(', ')}"
          redirect_to complaint_path(@complaint.access_token)
        end
      end
    end
  end

  def reports
    default_filters = { status: ['new', 'assigned', 'responded'] }
    filters = default_filters.merge(params.permit(:status, :report_type, :outcome).reject { |_k, v| v.blank? })
    @complaints = Complaint.includes(:comments, :user, :assignee).where(**filters).order(created_at: :desc)
                           .paginate(page: params[:page], per_page: 20)
    render layout: 'without_sidebar'
  end

  def self_assign
    update_params = { assignee: current_user }
    if @complaint.status == 'new'
      update_params.merge!(status: 'assigned', status_updated_at: DateTime.now)
    end

    @comment = @complaint.comments.new(user_id: -1, internal: true,
                                       content: "Report assigned to #{current_user.username}.")

    begin
      Complaint.transaction do
        @complaint.update!(update_params)
        @comment.save!
      end
    rescue ActiveRecord::RecordInvalid
      errors = @complaint.errors.full_messages + @comment.errors.full_messages
      flash[:danger] = "Couldn't assign you to this report (#{errors.join(', ')})"
    end

    redirect_to complaint_path(@complaint.access_token)
  end

  def update_status
    unless current_user&.same_as?(@complaint.assignee)
      flash[:danger] = 'You are not assigned to this report. Assign yourself before changing its status.'
      redirect_back fallback_location: complaint_path(@complaint.access_token) and return
    end

    new_status = AppConfig.safety_center['statuses'][params[:new_status]]
    if new_status.nil?
      flash[:danger] = 'Invalid status.'
      redirect_back fallback_location: complaint_path(@complaint.access_token) and return
    end

    update_params = { status: params[:new_status], status_updated_at: DateTime.now }
    update_params.merge!(outcome: params[:outcome]) unless params[:outcome].nil?
    @comment = @complaint.comments.new(user_id: -1, internal: true,
                                       content: "Status changed to #{new_status['name']} by #{current_user.username}.")

    begin
      Complaint.transaction do
        @complaint.update!(update_params)
        @comment.save!
      end
    rescue ActiveRecord::RecordInvalid
      errors = @complaint.errors.full_messages + @comment.errors.full_messages
      flash[:danger] = "Couldn't change status of this report (#{errors.join(', ')})"
    end

    redirect_to complaint_path(@complaint.access_token)
  end

  def reporting
    @total = Complaint.recent(12.months.ago).count
    @by_type = Complaint.recent(12.months.ago).group(:report_type).group_by_month(:created_at).count
    @by_content_type = Complaint.recent(12.months.ago).where(report_type: 'illegal')
                             .group(:content_type).group_by_month(:created_at).count
    @by_outcome = Complaint.recent(12.months.ago).where.not(outcome: nil)
                           .group(:outcome).group_by_month(:created_at).count
    @type_totals = Complaint.recent(12.months.ago).group(:report_type).count
    render layout: 'without_sidebar'
  end

  private

  def access_check
    # rubocop:disable Lint/DuplicateBranch
    if user_signed_in? && (current_user.staff? || current_user == @complaint.user)
      # only allow complainants to access their own complaints regardless of access token
      true
    elsif !user_signed_in? && @complaint.user.nil?
      # if not signed in then we're just relying on the access token as proof of access as long as user is nil
      true
    else
      not_found!
    end
    # rubocop:enable Lint/DuplicateBranch
  end

  def write_access_check
    if user_signed_in? && current_user.staff?
      true
    else
      not_found!
    end
  end

  def set_complaint
    @complaint = Complaint.includes(:comments, :assignee, comments: :user).where(access_token: params[:token]).first

    if @complaint.nil?
      not_found!
    end

    @complaint
  end
end
