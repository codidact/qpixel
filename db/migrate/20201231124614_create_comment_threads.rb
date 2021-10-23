class CreateCommentThreads < ActiveRecord::Migration[5.2]
  def change
    create_table :comment_threads do |t|
      t.string :title
      t.integer :reply_count
      t.references :post

      t.boolean :locked
      t.references :locked_by, foreign_key: {to_table: :users}, null: true
      t.timestamp :locked_until, null: true

      t.boolean :archived
      t.references :archived_by, foreign_key: {to_table: :users}, null: true
      t.timestamp :archived_until, null: true
      t.boolean :ever_archived_before

      t.boolean :deleted
      t.references :deleted_by, foreign_key: {to_table: :users}, null: true

      t.timestamps
    end

    add_reference :comments, :comment_thread, null: true

    add_column :comments, :has_reference, :boolean
    add_column :comments, :reference_text, :text, null: true
    add_reference :comments, :references_comment, foreign_key: {to_table: :comments}, null: true
  end
end
