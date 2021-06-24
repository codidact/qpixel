class AddDefaults < ActiveRecord::Migration[5.2]
  def change
    change_column :comment_threads, :reply_count, :integer, null: false, default: 0
    change_column :comment_threads, :locked, :boolean, null: false, default: false
    change_column :comment_threads, :deleted, :boolean, null: false, default: false
    change_column :comment_threads, :archived, :boolean, null: false, default: false
    Comment.unscoped.where(has_reference: nil).update_all(has_reference: false)
    change_column :comments, :has_reference, :boolean, null: false, default: false
  end
end
