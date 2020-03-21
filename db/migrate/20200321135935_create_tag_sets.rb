class CreateTagSets < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_sets do |t|
      t.string :name
      t.references :community, index: true, null: false

      t.timestamps
    end
  end
end
