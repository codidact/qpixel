class CreateLicenses < ActiveRecord::Migration[5.2]
  def change
    create_table :licenses do |t|
      t.string :name
      t.string :url
      t.boolean :default
      t.bigint :community_id, null: false

      t.timestamps
    end

    add_index :licenses, :community_id
    add_index :licenses, :name
  end
end
