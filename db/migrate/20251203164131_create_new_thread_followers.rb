class CreateNewThreadFollowers < ActiveRecord::Migration[7.2]
  def change
    create_table :new_thread_followers do |t|
      t.bigint :user_id
      t.bigint :post_id

      t.timestamps
    end
    add_index :new_thread_followers, :user_id
    add_index :new_thread_followers, :post_id
  end
end
