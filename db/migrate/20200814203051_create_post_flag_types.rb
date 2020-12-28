class CreatePostFlagTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :post_flag_types do |t|
      t.references :community
      t.string :name
      t.text :description
      t.boolean :confidential
      t.boolean :active
      t.references :post_type, null: true
      t.timestamps
    end
  end
end
