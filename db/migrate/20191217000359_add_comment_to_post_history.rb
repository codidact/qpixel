class AddCommentToPostHistory < ActiveRecord::Migration[5.2]
  def change
    add_column :post_histories, :comment, :text
  end
end
