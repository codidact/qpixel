class ComplaintsController < ApplicationController
  before_action :set_complaint, only: [:show, :comment]
  before_action :access_check, only: [:show, :comment]

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
          render json: { status: 'failed', message: "Couldn't save your reply", errors: @comment.errors.full_messages }
        end
        format.html do
          flash[:danger] = "Couldn't save your reply: #{@comment.errors.full_messages.join(', ')}"
          redirect_to complaint_path(@complaint.access_token)
        end
      end
    end
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
      raise ActiveRecord::RecordNotFound
    end
    # rubocop:enable Lint/DuplicateBranch
  end

  def write_access_check
    if user_signed_in? && current_user.staff?
      true
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def set_complaint
    @complaint = Complaint.includes(:comments, :assignee, comments: :user).where(access_token: params[:token]).first

    if @complaint.nil?
      raise ActiveRecord::RecordNotFound, "Complaint not found with token=#{params[:token]}"
    end

    @complaint
  end
end
