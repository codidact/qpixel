class CreateUserWebsites < ActiveRecord::Migration[7.0]
  def change
    create_table :user_websites do |t|
      t.column :label, :string, limit:80
      t.string :url
      t.integer :position
    end
    add_reference :user_websites, :user, null: false, foreign_key: true
    add_index(:user_websites, [:user_id, :url], unique: true)
  end
end
