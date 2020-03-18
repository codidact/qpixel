class CloseReasonsController < ApplicationController
  def index
    if @current_user.is_admin and params[:global] == "1"
      @close_reasons = CloseReason.where(community_id: nil)
    else
      @close_reasons = CloseReason.where(community_id: @community.id)
    end
  end

  def edit
    @close_reason = CloseReason.find(params[:id])
  end

  def update
    puts params
    @close_reason = CloseReason.find(params[:id])
    @close_reason.update(name: params[:close_reason][:name],
                         description: params[:close_reason][:description],
                         requires_other_post: params[:close_reason][:requires_other_post],
                         active: params[:close_reason][:active])

    if @close_reason.community.nil?
      redirect_to '/close_reasons?global=1'
    else
      redirect_to '/close_reasons'
    end
  end
end
