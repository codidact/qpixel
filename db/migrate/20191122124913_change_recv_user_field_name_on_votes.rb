class ChangeRecvUserFieldNameOnVotes < ActiveRecord::Migration[5.0]
  def change
    rename_column :votes, :recv_user, :recv_user_id
  end
end
