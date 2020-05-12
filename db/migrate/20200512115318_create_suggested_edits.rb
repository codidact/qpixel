class CreateSuggestedEdits < ActiveRecord::Migration[5.2]
  def change
    create_table :suggested_edits do |t|
      t.references :posts, foreign_key: true
      t.references :users, foreign_key: true
      t.references :community, foreign_key: true
      
      t.string :body, null: true
      t.string :title, null: true
      t.string :tags_cache, null: true
      t.string :body_markdown, null: true
      
      t.boolean :active
      t.boolean :accepted
      t.datetime :decided_at
      t.references :decided_by, foreign_key: {to_table: :users}, null: true
      t.string :rejected_comment

      t.timestamps
    end
  end

  create_join_table :suggested_edits, :tags
end
