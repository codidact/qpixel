class AddLastActivityToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :last_activity, :datetime, default: -> { 'CURRENT_TIMESTAMP' }, null: false
  end
end
