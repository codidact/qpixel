class AddHiddenToPostHistory < ActiveRecord::Migration[7.0]
  def change
    add_column :post_histories, :hidden, :boolean, null: false, default: false
  end
end
