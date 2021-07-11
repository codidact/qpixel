class CreateReactions < ActiveRecord::Migration[5.2]
  def change
    create_table :reactions do |t|
      t.references :users
      t.references :reaction_types
      t.references :posts
      t.references :comments
      t.timestamps
    end
  end
end
