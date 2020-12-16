class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :stop_the_awful_troll
  helper_method :phrase_for

  def new
    @phrasing = phrase_for params[:type]
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new sub_params.merge(user: current_user)
    if @subscription.save
      flash[:success] = 'Your subscription was saved successfully.'
      redirect_to params[:return_to].presence || root_path
    else
      render :error, status: :internal_server_error
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
        render json: { status: 'failed' }, status: :internal_server_error
      end
    else
      render json: { status: 'failed', message: 'You do not have permission to update this subscription.' },
             status: :forbidden
    end
  end

  def destroy
    @subscription = Subscription.find params[:id]
    if current_user.is_admin || current_user.id == @subscription.user_id
      if @subscription.destroy
        render json: { status: 'success' }
      else
        render json: { status: 'failed' }, status: :internal_server_error
      end
    else
      render json: { status: 'failed', message: 'You do not have permission to remove this subscription.' },
             status: :forbidden
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
    when 'moderators'
      'announcements and newsletters for moderators'
    else
      'nothing, apparently. How did you get here, again?'
    end
  end

  private

  def sub_params
    params.require(:subscription).permit(:type, :qualifier, :frequency, :name)
  end
end
