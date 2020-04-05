# Provides web and API actions relating to user notifications.
class NotificationsController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @notifications = Notification.where(user: current_user).paginate(page: params[:page], per_page: 100)
                                 .order(Arel.sql('is_read ASC, created_at DESC'))
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @notifications }
    end
  end

  def read
    @notification = Notification.find params[:id]

    unless @notification.user == current_user
      respond_to do |format|
        format.html { render template: 'errors/forbidden', status: 401 }
        format.json { render json: nil, status: 401 }
      end
      return
    end

    @notification.is_read = true
    if @notification.save
      respond_to do |format|
        format.html do
          flash[:notice] = 'Marked as read.'
          render :index
        end
        format.json { render json: { status: 'success' } }
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
    @notifications = Notification.where(user: current_user, is_read: false)
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
