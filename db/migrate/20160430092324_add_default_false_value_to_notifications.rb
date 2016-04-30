class AddDefaultFalseValueToNotifications < ActiveRecord::Migration
  def change
    change_column :notifications, :is_read, :boolean, :default => false
  end
end
