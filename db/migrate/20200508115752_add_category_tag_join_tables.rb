class AddCategoryTagJoinTables < ActiveRecord::Migration[5.2]
  def change
    create_table :categories_required_tags, id: false, primary_key: [:category_id, :tag_id] do |t|
      t.bigint :category_id
      t.bigint :tag_id
    end

    create_table :categories_topic_tags, id: false, primary_key: [:category_id, :tag_id] do |t|
      t.bigint :category_id
      t.bigint :tag_id
    end
  end
end
