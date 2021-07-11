class CreateReactionTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :reaction_types do |t|
      t.string :name
      t.text :description
      t.string :on_post_label

      t.string :icon
      t.string :color
      
      t.boolean :requires_comment
      
      t.references :community
      t.integer :position
      
      t.timestamps
    end
  end
end
