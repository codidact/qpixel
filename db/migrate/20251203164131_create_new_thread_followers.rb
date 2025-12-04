class CreateNewThreadFollowers < ActiveRecord::Migration[7.2]
  def change
    create_table_new_thread_followers
    move_rows_with_non_nil_post_id
    remove_post_id_column_from_thread_followers
  end

  def create_table_new_thread_followers
    create_table :new_thread_followers do |t|
      t.bigint :user_id
      t.bigint :post_id

      t.timestamps
    end
    add_index :new_thread_followers, :user_id
    add_index :new_thread_followers, :post_id
  end

  def move_rows_with_non_nil_post_id
    NewThreadFollower.insert_all(
      ThreadFollower.select(:user_id, :post_id, :created_at, :updated_at).where.not(post_id:nil)
    )
  end

  def remove_post_id_column_from_thread_followers
    change_table :thread_followers do |t|
      t.remove :post_id
    end
  end
end
