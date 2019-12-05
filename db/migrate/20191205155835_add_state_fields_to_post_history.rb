class AddStateFieldsToPostHistory < ActiveRecord::Migration[5.2]
  def change
    add_column :post_histories, :before_state, :text
    add_column :post_histories, :after_state, :text
  end
end
