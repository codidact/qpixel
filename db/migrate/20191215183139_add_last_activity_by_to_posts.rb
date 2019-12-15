class AddLastActivityByToPosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :last_activity_by, class_name: 'User'
  end
end
