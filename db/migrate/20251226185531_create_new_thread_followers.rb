class CreateNewThreadFollowers < ActiveRecord::Migration[7.2]
  def up
    create_table_new_thread_followers
    if column_exists?(:thread_followers, :post_id)
      move_rows_with_non_nil_post_id
      remove_post_id_column_from_thread_followers
    end
  end

  def down
    if !column_exists?(:thread_followers, :post_id)
      add_post_id_column_to_thread_followers
    end
    move_rows_back_from_new_thread_followers
    delete_table_new_thread_followers
  end

  def create_table_new_thread_followers
    create_table :new_thread_followers, if_not_exists: true do |t|
      t.bigint :user_id
      t.bigint :post_id

      t.timestamps
    end
    add_index :new_thread_followers, [:user_id, :post_id], if_not_exists: true
    add_index :new_thread_followers, :post_id, if_not_exists: true
  end

  def move_rows_with_non_nil_post_id
    NewThreadFollower.insert_all(
      ThreadFollower.select(:user_id, :post_id, :created_at, :updated_at)
        .where.not(post_id:nil)
        .to_a
        .map(&:attributes)
    )
    ThreadFollower.where.not(post_id:nil).delete_all
  end

  def remove_post_id_column_from_thread_followers
    remove_reference :thread_followers, :post, index: true, foreign_key: true, if_exists: true
  end

  def add_post_id_column_to_thread_followers
    add_reference :thread_followers, :post, index: true, foreign_key: true, if_not_exists: true
  end

  def move_rows_back_from_new_thread_followers
    ThreadFollower.insert_all(
      NewThreadFollower.select(:user_id, :post_id, :created_at, :updated_at)
        .to_a
        .map(&:attributes)
    )
    NewThreadFollower.delete_all
  end

  def delete_table_new_thread_followers
    remove_index :new_thread_followers, :post_id, if_exists: true
    remove_index :new_thread_followers, [:user_id, :post_id], if_exists: true
    remove_reference :new_thread_followers, :user_id, foreign_key: true, if_exists: true
    remove_reference :new_thread_followers, :post_id, foreign_key: true, if_exists: true
    drop_table :new_thread_followers, if_exists: true
  end
end
