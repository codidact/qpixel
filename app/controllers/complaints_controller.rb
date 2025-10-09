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
        redirect_to safety_center_path # report path
      else
        @errors = @comment.errors.full_messages
        render :report, status: :bad_request, layout: 'without_sidebar'
      end
    else
      @errors = @complaint.errors.full_messages
      render :report, status: :bad_request, layout: 'without_sidebar'
    end
  end
end
