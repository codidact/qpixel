# Provides web and API actions relating to user notifications.
class NotificationsController < ApplicationController
  before_action :authenticate_user!, :only => [:index]

  # Authenticated web/API action. Retrieves a list of active notifications for the current user.
  def index

  end

  # Authenticated web/API action. Marks a single notification as read.
  def read

  end

  # Authenticated web/API action. Marks all the current user's unread notifications as read.
  def read_all

  end
end
