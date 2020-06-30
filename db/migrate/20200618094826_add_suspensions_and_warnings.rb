class AddSuspensionsAndWarnings < ActiveRecord::Migration[5.2]
  def change
    create_table :warnings do |t|
      t.references :community_user, foreign_key: true
      
      t.text :body, null: true
      t.boolean :is_suspension
      t.datetime :suspension_end     
      t.boolean :active
      
      t.references :author, foreign_key: {to_table: :users}, null: true

      t.timestamps
    end

    add_column :community_users, :is_suspended, :boolean
    add_column :community_users, :suspension_end, :datetime
    add_column :community_users, :suspension_public_comment, :string
  end
end
