# Provides web and API actions relating to user notifications.
class NotificationsController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @notifications = Notification.unscoped.where(user: current_user).paginate(page: params[:page], per_page: 100)
                                 .order(Arel.sql('is_read ASC, created_at DESC'))
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @notifications, methods: :community_name }
    end
  end

  def read
    @notification = Notification.unscoped.find params[:id]

    unless @notification.user == current_user
      respond_to do |format|
        format.html { render template: 'errors/forbidden', status: :forbidden }
        format.json { render json: nil, status: :forbidden }
      end
      return
    end

    @notification.is_read = !@notification.is_read
    if @notification.save
      respond_to do |format|
        format.html do
          flash[:notice] = 'Marked as read.'
          render :index
        end
        format.json { render json: { status: 'success', notification: @notification }, methods: :community_name }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = 'Failed to mark read.'
          render :index
        end
        format.json { render json: { status: 'failed' } }
      end
    end
  end

  def read_all
    @notifications = Notification.unscoped.where(user: current_user, is_read: false)
    if @notifications.update_all(is_read: true)
      respond_to do |format|
        format.html do
          flash[:notice] = 'Marked all as read.'
          render :index
        end
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = 'Failed to mark all read.'
          render :index
        end
        format.json { render json: { status: 'failed' } }
      end
    end
  end
end
