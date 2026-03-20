class AbilitiesController < ApplicationController
  before_action :set_ability, only: [:show, :edit, :update]
  before_action :set_user
  before_action :verify_global_admin, only: [:edit, :update]
  before_action :verify_moderator, only: [:recalc]

  def index
    @abilities = Ability.all
  end

  def show
    @ability = Ability.where(internal_id: params[:id]).first
    @your_ability = @user&.community_user&.privilege @ability.internal_id
  end

  def edit end

  def update
    update_params = {}

    if @ability.update(update_params)

      redirect_to ability_path(id: @ability.id)
    else
      render :edit, status: :bad_request
    end
  end

  def recalc
    @user.community_user.recalc_privileges!
    redirect_to user_privileges_url(@user.id)
  end

  private

  def set_ability
    @ability = Ability.where(internal_id: params[:id]).first
    return not_found! unless @ability.present?
  end

  def set_user
    @user = if params[:for].present?
              User.where(id: params[:for]).first || @user
            else
              current_user
            end
  end
end
