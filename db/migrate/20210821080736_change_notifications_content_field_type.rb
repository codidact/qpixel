class ChangeNotificationsContentFieldType < ActiveRecord::Migration[5.2]
  def change
    change_column :notifications, :content, :text
  end
end