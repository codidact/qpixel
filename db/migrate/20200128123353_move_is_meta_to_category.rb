class MoveIsMetaToCategory < ActiveRecord::Migration[5.2]
  def change
    change_column :posts, :category, :string, default: 'Main'
    Post.where(is_meta: true).update_all(category: 'Meta')
    Post.where(is_meta: [false, nil]).update_all(category: 'Main')
    remove_column :posts, :is_meta
  end
end
