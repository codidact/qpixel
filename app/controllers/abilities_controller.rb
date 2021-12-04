class AbilitiesController < ApplicationController
  before_action :set_user
  before_action :verify_moderator, only: [:recalc]

  def index
    @abilities = Ability.all
  end

  def show
    @ability = Ability.where(internal_id: params[:id]).first
    return not_found if @ability.nil?

    @your_ability = @user&.community_user&.privilege @ability.internal_id
  end

  def recalc
    @user.community_user.recalc_privileges
    redirect_to user_privileges_url(@user.id)
  end

  private

  def set_user
    @user = if params[:for].present?
              User.where(id: params[:for]).first || @user
            else
              current_user
            end
  end
end
