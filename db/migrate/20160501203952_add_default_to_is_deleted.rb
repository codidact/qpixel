class AddDefaultToIsDeleted < ActiveRecord::Migration
  def change
    change_column :answers, :is_deleted, :boolean, default: false
    change_column :comments, :is_deleted, :boolean, default: false
  end
end
