class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def new
    @phrasing = case params[:type]
                when 'all'
                  'all new questions'
                when 'tag'
                  "new questions in the tag '#{Tag.find_by(name: params[:qualifier])&.name}'"
                when 'user'
                  "new questions by the user '#{User.find_by(id: params[:qualifier])&.username}'"
                when 'interesting'
                  'new questions classed as interesting'
                else
                  'nothing, apparently. How did you get here, again?'
                end
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new sub_params.merge(user: current_user)
    if @subscription.save
      flash[:success] = 'Your subscription was saved successfully.'
      redirect_to params[:return_to].present? ? params[:return_to] : root_path
    else
      render :error
    end
  end

  private

  def sub_params
    params.require(:subscription).permit(:type, :qualifier, :frequency, :name)
  end
end
