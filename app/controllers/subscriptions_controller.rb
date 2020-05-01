class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  helper_method :phrase_for

  def new
    @phrasing = phrase_for params[:type]
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new sub_params.merge(user: current_user)
    if @subscription.save
      flash[:success] = 'Your subscription was saved successfully.'
      redirect_to params[:return_to].present? ? params[:return_to] : root_path
    else
      render :error, status: 500
    end
  end

  def index
    @subscriptions = current_user.subscriptions
  end

  def enable
    @subscription = Subscription.find params[:id]
    if current_user.is_admin || current_user.id == @subscription.user_id
      if @subscription.update(enabled: params[:enabled] || false)
        render json: { status: 'success', subscription: @subscription }
      else
        render json: { status: 'failed' }, status: 500
      end
    else
      render json: { status: 'failed', message: 'You do not have permission to update this subscription.' }, status: 403
    end
  end

  def destroy
    @subscription = Subscription.find params[:id]
    if current_user.is_admin || current_user.id == @subscription.user_id
      if @subscription.destroy
        render json: { status: 'success' }
      else
        render json: { status: 'failed' }, status: 500
      end
    else
      render json: { status: 'failed', message: 'You do not have permission to remove this subscription.' }, status: 403
    end
  end

  protected

  def phrase_for(type, qualifier = nil)
    case type
    when 'all'
      'all new questions'
    when 'tag'
      "new questions in the tag '#{Tag.find_by(name: qualifier || params[:qualifier])&.name}'"
    when 'user'
      "new questions by the user '#{User.find_by(id: qualifier || params[:qualifier])&.username}'"
    when 'interesting'
      'new questions classed as interesting'
    when 'category'
      "new questions in the category '#{Category.find_by(id: qualifier || params[:qualifier])&.name}'"
    else
      'nothing, apparently. How did you get here, again?'
    end
  end

  private

  def sub_params
    params.require(:subscription).permit(:type, :qualifier, :frequency, :name)
  end
end
