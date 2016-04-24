class AddPolymorphicPostToVotes < ActiveRecord::Migration
  def change
    add_reference :votes, :post, polymorphic: true, index: true
  end
end
