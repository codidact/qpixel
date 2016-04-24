class RemovePostFromVotes < ActiveRecord::Migration
  def change
    remove_reference :votes, :post, index: true, foreign_key: true
  end
end
