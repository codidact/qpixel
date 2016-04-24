class RenameVotesTypeToVotesVoteType < ActiveRecord::Migration
  def change
    rename_column :votes, :type, :vote_type
  end
end
