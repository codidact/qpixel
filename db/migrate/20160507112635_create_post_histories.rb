class CreatePostHistories < ActiveRecord::Migration
  def change
    create_table :post_histories do |t|
      t.references :post_history_type, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.string :title
      t.string :body
      t.string :tags

      t.timestamps null: false
    end
  end
end
