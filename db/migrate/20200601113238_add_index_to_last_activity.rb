class AddIndexToLastActivity < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :last_activity
  end
end
