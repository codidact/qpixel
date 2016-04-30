class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :content
      t.string :link
      t.boolean :is_read

      t.timestamps null: false
    end
  end
end
