class CreatePostHistoryTags < ActiveRecord::Migration[5.2]
  def change
    create_table :post_history_tags do |t|
      t.references :post_history, foreign_key: true
      t.references :tag, foreign_key: true
      t.string :relationship

      t.timestamps
    end
  end
end
