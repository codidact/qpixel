class ComplaintsController < ApplicationController
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
    if @complaint.save
      @comment = ComplaintComment.new(comment_params.merge(complaint: @complaint, internal: false))
      if @comment.save
        redirect_to complaint_path(@complaint.access_token)
      else
        @errors = @comment.errors.full_messages
        render :report, status: :bad_request, layout: 'without_sidebar'
      end
    else
      @errors = @complaint.errors.full_messages
      render :report, status: :bad_request, layout: 'without_sidebar'
    end
  end

  def show
    @complaint = Complaint.includes(:comments, :assignee, comments: :user).where(access_token: params[:token]).first

    if @complaint.nil?
      raise ActiveRecord::RecordNotFound, "Complaint not found with token=#{params[:token]}"
    end

    return unless access_check(@complaint)

    @report_type = AppConfig.safety_center['report_types'][@complaint.report_type]
    @content_type = AppConfig.safety_center['content_types'][@complaint.content_type]
    @status = AppConfig.safety_center['statuses'][@complaint.status]
    render layout: 'without_sidebar'
  end

  private

  def access_check(complaint)
    # rubocop:disable Lint/DuplicateBranch
    if user_signed_in? && (current_user.staff? || current_user == complaint.user)
      # only allow complainants to access their own complaints regardless of access token
      true
    elsif !user_signed_in?
      # if not signed in then we're just relying on the access token as proof of access
      true
    else
      raise ActiveRecord::RecordNotFound
    end
    # rubocop:enable Lint/DuplicateBranch
  end
end
