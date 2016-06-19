class AddReceivingUserToVotes < ActiveRecord::Migration
  def change
    add_column :votes, :recv_user, :integer
  end
end
