class CloseReasonsController < ApplicationController
  def index
    if @current_user.nil? or (not @current_user.is_admin and not @current_user.is_moderator); not_found and return; end

    if @current_user.is_admin and params[:global] == "1"
      @close_reasons = CloseReason.where(community_id: nil)
    else
      @close_reasons = CloseReason.where(community_id: @community.id)
    end
  end

  def edit
    if @current_user.nil? or (not @current_user.is_admin and not @current_user.is_moderator); not_found and return; end

    @close_reason = CloseReason.find(params[:id])

    if !@current_user.is_admin and @close_reason.community.nil?
      not_found
    end
  end

  def update
    if @current_user.nil? or (not @current_user.is_admin and not @current_user.is_moderator); not_found and return; end

    @close_reason = CloseReason.find(params[:id])

    if !@current_user.is_admin and @close_reason.community.nil?
      not_found
    end

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

  def new
    if @current_user.nil? or (not @current_user.is_admin and not @current_user.is_moderator); not_found and return; end

    if !@current_user.is_admin and params[:global] == "1"
      not_found
    end

    @close_reason = CloseReason.new
  end

  def create
    if @current_user.nil? or (not @current_user.is_admin and not @current_user.is_moderator); not_found and return; end

    if !@current_user.is_admin and params[:global] == "1"
      not_found
    end

    @close_reason = CloseReason.new(name: params[:close_reason][:name],
                                    description: params[:close_reason][:description],
                                    requires_other_post: params[:close_reason][:requires_other_post],
                                    active: params[:close_reason][:active],
                                    community: (params[:global] == "1") ? nil : @community)
    if @close_reason.save
      if @close_reason.community.nil?
        redirect_to '/close_reasons?global=1'
      else
        redirect_to '/close_reasons'
      end
    else
      render :new
    end
  end
end
