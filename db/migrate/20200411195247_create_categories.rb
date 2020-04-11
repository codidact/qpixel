class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :name
      t.text :short_wiki
      t.references :community

      t.timestamps
    end
  end
end
