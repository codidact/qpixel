class AddFieldsToPostHistory < ActiveRecord::Migration[7.0]
  def change
    add_reference :post_histories, :close_reason, foreign_key: true
    add_reference :post_histories, :duplicate_post, foreign_key: { to_table: :posts }
    add_reference :post_histories, :reverted_with, foreign_key: { to_table: :post_histories }
  end
end
