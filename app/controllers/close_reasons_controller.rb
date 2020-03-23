class CloseReasonsController < ApplicationController
  before_action :verify_moderator

  def index
    if @current_user.is_global_admin && params[:global] == "1"
      @close_reasons = CloseReason.where(community_id: nil)
    else
      @close_reasons = CloseReason.where(community_id: @community.id)
    end
  end

  def edit
    @close_reason = CloseReason.find(params[:id])

    if !@current_user.is_global_admin && @close_reason.community.nil?
      not_found
      return
    end
  end

  def update
    @close_reason = CloseReason.find(params[:id])

    if !@current_user.is_global_admin && @close_reason.community.nil?
      not_found
      return
    end

    @close_reason.update close_reason_params

    if @close_reason.community.nil?
      redirect_to close_reasons_path(global: 1)
    else
      redirect_to close_reasons_path
    end
  end

  def new
    if !@current_user.is_global_admin && params[:global] == "1"
      not_found
      return
    end

    @close_reason = CloseReason.new
  end

  def create
    if !@current_user.is_global_admin && params[:global] == "1"
      not_found
      return
    end

    @close_reason = CloseReason.new(name: params[:close_reason][:name],
                                    description: params[:close_reason][:description],
                                    requires_other_post: params[:close_reason][:requires_other_post],
                                    active: params[:close_reason][:active],
                                    community: (params[:global] == "1") ? nil : @community)
    if @close_reason.save
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
