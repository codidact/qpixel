class AddPostToPostHistory < ActiveRecord::Migration
  def change
    add_reference :post_history, :post, polymorphic: true, index: true
  end
end
