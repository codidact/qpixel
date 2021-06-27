class MakeFlagsPolymorphic < ActiveRecord::Migration[5.2]
  def change
    add_column :flags, :post_type, :string
    Flag.all.update_all(post_type: 'Post')
    remove_index :flags, name: :index_flags_on_post_type_and_post_id
    add_index :flags, [:post_type, :post_id]
  end
end
