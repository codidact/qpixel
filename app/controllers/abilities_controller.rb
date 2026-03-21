class AbilitiesController < ApplicationController
  include DraftManagement

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_ability, only: [:show, :edit, :update]
  before_action :set_user
  before_action :verify_moderator, only: [:edit, :recalc, :update]

  def index
    @abilities = Ability.all
  end

  def show
    @your_ability = @user&.community_user&.privilege @ability.internal_id
  end

  def edit; end

  def update
    if push_to_network?(@ability)
      abilities = Ability.unscoped.where(internal_id: @ability.internal_id,
                                         description: @ability.description)

      if do_update_network(@ability, abilities)
        do_delete_draft(current_user, URI(request.referer || '').path)
        flash[:success] = "#{helpers.pluralize(abilities.to_a.size, 'ability')} updated."
        redirect_to ability_path(id: @ability.internal_id)
      else
        render :edit, status: :bad_request
      end
    elsif @ability.update(ability_update_params)
      do_delete_draft(current_user, URI(request.referer || '').path)
      flash[:success] = I18n.t('abilities.success.update_generic')
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

  # Actually update a given set of abilities network-wide
  # @param ability [Ability] ability from which the push is initiated
  # @param abilities [ActiveRecord::Relation<Ability>] network abilities to update
  # @return [Boolean] status of the operation
  def do_update_network(ability, abilities)
    Ability.transaction do
      abilities.each do |network_ability|
        unless network_ability.update(ability_update_params)
          ability.errors.merge!(network_ability.errors)
          raise ActiveRecord::Rollback
        end
      end
      true
    rescue
      false
    end
  end

  # Should push to network?
  # @param ability [Ability] ability to check
  # @return [Boolean] check result
  def push_to_network?(ability)
    return false unless params[:network_push] == 'true'
    return false unless current_user.present?

    current_user.can_push_to_network?(ability)
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
