class RemovePostFieldsFromPostHistory < ActiveRecord::Migration
  def change
    remove_column :post_histories, :title, :string
    remove_column :post_histories, :body, :string
    remove_column :post_histories, :tags, :string
  end
end
