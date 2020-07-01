class AddIndexToPostScore < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :score
  end
end
