class CreateThreadFollowers < ActiveRecord::Migration[5.2]
  def change
    create_table :thread_followers do |t|
      t.references :comment_thread
      t.references :user
      t.timestamps
    end
  end
end
