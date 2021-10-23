class RemoveSuspiciousVotes < ActiveRecord::Migration[5.2]
  def change
    drop_table :suspicious_votes
  end
end
