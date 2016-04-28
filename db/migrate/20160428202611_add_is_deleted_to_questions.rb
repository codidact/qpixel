class AddIsDeletedToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :is_deleted, :boolean
  end
end
