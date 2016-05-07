class AddPostToPostHistory < ActiveRecord::Migration
  def change
    add_reference :post_histories, :post, polymorphic: true, index: true
  end
end
