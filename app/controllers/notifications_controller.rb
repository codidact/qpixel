# Provides web and API actions relating to user notifications.
class NotificationsController < ApplicationController
  before_action :authenticate_user!, :only => [:index]

  # Authenticated web/API action. Retrieves a list of active notifications for the current user.
  def index
    @notifications = Notification.where(:user => current_user, :is_read => false).paginate(:page => params[:page], :per_page => 100).order('created_at DESC')
    respond_to do |format|
      format.html { render :index }
      format.json { render :json => @notifications }
    end
  end

  # Authenticated web/API action. Marks a single notification as read.
  def read
    @notification = Notification.find params[:id]

    unless @notification.user == current_user
      respond_to do |format|
        format.html { render :template => 'errors/forbidden', :status => 401 }
        format.json { render :head => 401 }
    end

    @notification.is_read = true
    if @notification.save
      respond_to do |format|
        format.html {
          flash[:notice] = "Marked as read."
          render :index
        }
        format.json { render :json => { :status => 'success' } }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = "Failed to mark read."
          render :index
        }
        format.json { render :json => { :status => 'failed' } }
      end
    end
  end

  # Authenticated web/API action. Marks all the current user's unread notifications as read.
  def read_all
    @notifications = Notification.where(:user => current_user, :is_read => false)
    if @notifications.update_all(is_read: true)
      respond_to do |format|
        format.html {
          flash[:notice] = "Marked all as read."
          render :index
        }
        format.json { render :json => { :status => 'success' } }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = "Failed to mark all read."
          render :index
        }
        format.json { render :json => { :status => 'failed' } }
      end
    end
  end
end
