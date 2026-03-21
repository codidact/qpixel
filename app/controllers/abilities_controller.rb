class AbilitiesController < ApplicationController
  include DraftManagement

  before_action :set_ability, only: [:show, :edit, :update]
  before_action :set_user
  before_action :verify_global_admin, only: [:edit, :update]
  before_action :verify_moderator, only: [:recalc]

  def index
    @abilities = Ability.all
  end

  def show
    @your_ability = @user&.community_user&.privilege @ability.internal_id
  end

  def edit; end

  def update
    if @ability.update(ability_update_params)
      do_delete_draft(current_user, URI(request.referer || '').path)
      redirect_to ability_path(id: @ability.internal_id)
    else
      render :edit, status: :bad_request
    end
  end

  def recalc
    @user.community_user.recalc_privileges!
    redirect_to user_privileges_url(@user.id)
  end

  private

  def ability_update_params
    params.require(:ability).permit(:description)
  end

  def set_ability
    @ability = Ability.where(internal_id: params[:id]).first
    not_found! unless @ability.present?
  end

  def set_user
    @user = if params[:for].present?
              User.where(id: params[:for]).first || @user
            else
              current_user
            end
  end
end
