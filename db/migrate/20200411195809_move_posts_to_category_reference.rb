class MovePostsToCategoryReference < ActiveRecord::Migration[5.2]
  def change
    rename_column :posts, :category, :old_category
    add_reference :posts, :category

    Community.all.each do |community|
      main_category = Category.unscoped.find_or_create_by(community: community, name: 'Main')
      meta_category = Category.unscoped.find_or_create_by(community: community, name: 'Meta')

      Post.unscoped.where(community: community, old_category: 'Main').update_all(category_id: main_category.id)
      Post.unscoped.where(community: community, old_category: 'Meta').update_all(category_id: meta_category.id)
    end

    remove_column :posts, :old_category
  end
end
