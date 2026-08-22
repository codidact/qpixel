class AddLastActivityAtToComments < ActiveRecord::Migration[7.2]
  def change
    add_column :comments, :last_activity_at, :datetime
  end
end
