class AddCloseFieldsToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :is_closed, :boolean
    add_column :questions, :closed_by, :integer
    add_column :questions, :closed_at, :timestamp
  end
end
