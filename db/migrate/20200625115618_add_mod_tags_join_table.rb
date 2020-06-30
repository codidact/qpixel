class AddModTagsJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :categories_moderator_tags, id: false, primary_key: [:category_id, :tag_id] do |t|
      t.bigint :category_id
      t.bigint :tag_id
    end
  end
end
