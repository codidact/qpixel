class CreateSuspiciousVotes < ActiveRecord::Migration
  def change
    create_table :suspicious_votes do |t|
      t.integer :from_user
      t.integer :to_user
      t.boolean :was_investigated, default: false
      t.integer :investigated_by
      t.timestamp :investigated_at
      t.integer :suspicious_count
      t.integer :total_count

      t.timestamps null: false
    end
  end
end
