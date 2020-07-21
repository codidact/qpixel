class AddTitleAndTagsToPostHistory < ActiveRecord::Migration[5.2]
  def change
    add_column :post_histories, :before_title, :string
    add_column :post_histories, :after_title, :string
  end
end
