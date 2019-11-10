class RemovePolymorphicAssocFields < ActiveRecord::Migration[5.0]
  def change
    drop_table :answers
    drop_table :questions
    remove_column :comments, :post_type
    remove_column :flags, :post_type
    remove_column :post_histories, :post_type
    remove_column :votes, :post_type
  end
end
