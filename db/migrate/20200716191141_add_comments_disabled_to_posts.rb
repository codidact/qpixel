class AddCommentsDisabledToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :comments_disabled, :boolean
  end
end
