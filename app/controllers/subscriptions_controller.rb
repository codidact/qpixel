class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :stop_the_awful_troll

  def new
    @subscription = Subscription.new(new_sub_params)
  end

  def create
    @subscription = Subscription.new sub_params.merge(user: current_user)
    if @subscription.save
      flash[:success] = 'Your subscription was saved successfully.'
      redirect_to params[:return_to].presence || root_path
    else
      render :new, status: :bad_request
    end
  end

  def index
    @subscriptions = current_user.subscriptions
  end

  def qualifiers
    per_page = 20

    @items = case params[:type]
             when 'category'
               Category.accessible_to(current_user)
                       .order(sequence: :asc, id: :asc)
             when 'tag'
               Tag.order(name: :asc)
             when 'user'
               User.accessible_to(current_user)
                   .joins(:community_user)
                   .undeleted
                   .where.not(community_users: { deleted: true })
                   .order(username: :asc)
             end

    @items = params[:q].present? ? @items&.search(params[:q]) : @items
    @items = @items&.paginate(page: params[:page], per_page: per_page).to_a

    @items = @items.map do |item|
      { id: item.is_a?(Tag) ? item.name : item.id, text: item.name }
    end

    render json: @items
  end

  def enable
    @subscription = Subscription.find params[:id]
    if current_user.admin? || current_user.id == @subscription.user_id
      if @subscription.update(enabled: params[:enabled] || false)
        render json: { status: 'success', subscription: @subscription }
      else
        render json: { status: 'failed',
                       message: 'Failed to update your subscription. Please report this bug on Meta.' },
               status: :internal_server_error
      end
    else
      render json: { status: 'failed',
                     message: 'You do not have permission to update this subscription.' },
             status: :forbidden
    end
  end

  def destroy
    @subscription = Subscription.find params[:id]
    if current_user.admin? || current_user.id == @subscription.user_id
      if @subscription.destroy
        render json: { status: 'success' }
      else
        render json: { status: 'failed',
                       message: 'Failed to remove your subscription. Please report this bug on Meta.' },
               status: :internal_server_error
      end
    else
      render json: { status: 'failed',
                     message: 'You do not have permission to remove this subscription.' },
             status: :forbidden
    end
  end

  private

  def new_sub_params
    params.permit(:type, :qualifier, :frequency, :name)
  end

  def sub_params
    params.require(:subscription).permit(:type, :qualifier, :frequency, :name)
  end
end
