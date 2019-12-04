class CreatePostTagsLinkTable < ActiveRecord::Migration[5.2]
  def change
    create_table :posts_tags, id: false, primary_key: [:post_id, :tag_id] do |t|
      t.references :tag
      t.references :post
    end
  end
end
