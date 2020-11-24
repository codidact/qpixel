class AddLockedUntilToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :locked_until, :datetime, null: true
  end
end
