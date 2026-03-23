class CreateComplaints < ActiveRecord::Migration[7.2]
  def change
    create_table :complaints do |t|
      t.references :user, null: true, foreign_key: true
      t.string :report_type
      t.string :status
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.boolean :user_wants_updates
      t.string :access_token

      t.timestamps

      t.index :access_token, unique: true
      t.index :report_type
      t.index :status
    end
  end
end
