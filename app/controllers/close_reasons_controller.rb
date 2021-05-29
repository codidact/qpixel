class CloseReasonsController < ApplicationController
  before_action :verify_moderator

  def index
    @close_reasons = if current_user.is_global_admin && params[:global] == '1'
                       CloseReason.unscoped.where(community_id: nil)
                     else
                       CloseReason.unscoped.where(community_id: @community.id)
                     end
  end

  def edit
    @close_reason = CloseReason.unscoped.find(params[:id])

    if !current_user.is_global_admin && @close_reason.community.nil?
      not_found
      nil
    end
  end

  def update
    @close_reason = CloseReason.unscoped.find(params[:id])

    if !current_user.is_global_admin && @close_reason.community.nil?
      not_found
      return
    end

    before = @close_reason.attributes.map { |k, v| "#{k}: #{v}" }.join(' ')
    @close_reason.update close_reason_params
    after = @close_reason.attributes.map { |k, v| "#{k}: #{v}" }.join(' ')
    AuditLog.moderator_audit(event_type: 'close_reason_update', related: @close_reason, user: current_user,
                             comment: "from <<CloseReason #{before}>>\nto <<CloseReason #{after}>>")

    if @close_reason.community.nil?
      redirect_to close_reasons_path(global: 1)
    else
      redirect_to close_reasons_path
    end
  end

  def new
    if !current_user.is_global_admin && params[:global] == '1'
      not_found
      return
    end

    @close_reason = CloseReason.new
  end

  def create
    if !current_user.is_global_admin && params[:global] == '1'
      not_found
      return
    end

    @close_reason = CloseReason.new(name: params[:close_reason][:name],
                                    description: params[:close_reason][:description],
                                    requires_other_post: params[:close_reason][:requires_other_post],
                                    active: params[:close_reason][:active],
                                    community: params[:global] == '1' ? nil : @community)
    if @close_reason.save
      attr = @close_reason.attributes_print
      AuditLog.moderator_audit(event_type: 'close_reason_create', related: @close_reason, user: current_user,
                               comment: "<<CloseReason #{attr}>>")
      if @close_reason.community.nil?
        redirect_to close_reasons_path(global: 1)
      else
        redirect_to close_reasons_path
      end
    else
      render :new
    end
  end

  private

  def close_reason_params
    params.require(:close_reason).permit(:name, :description, :requires_other_post, :active)
  end
end
