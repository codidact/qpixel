class AddMoreDefaultValues < ActiveRecord::Migration[7.2]
  def change
    change_column_default :votes, :created_at, '2000-01-01T00:00:00.000000Z'
    change_column_default :votes, :updated_at, '2000-01-01T00:00:00.000000Z'
  end
end
