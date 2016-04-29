class AddIsDeletedToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :is_deleted, :boolean
  end
end
