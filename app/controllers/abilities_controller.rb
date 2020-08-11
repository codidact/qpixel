class AbilitiesController < ApplicationController
  def index
    @abilities = TrustLevel.all
  end

  def show
    @ability = TrustLevel.where(internal_id: params[:id]).first
    return not_found if @ability.nil?

    @your_ability = current_user.community_user.privilege @ability.internal_id
  end

  def recalc
    current_user.community_user.recalc_privileges
    redirect_to abilities_url
  end
end
