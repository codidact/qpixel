class AddPostToComments < ActiveRecord::Migration
  def change
    add_reference :comments, :post, polymorphic: true, index: true
  end
end
