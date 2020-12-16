class AddLockedToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :locked, :boolean, null: false, default: false
    add_reference :posts, :locked_by, foreign_key: { to_table: :users }, null: true
    add_column :posts, :locked_at, :datetime, null: true
  end
end
