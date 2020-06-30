class AddWarningTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :warning_templates do |t|
      t.references :community, foreign_key: true
      
      t.string :name
      t.text :body
      t.boolean :active
      
      t.timestamps
    end
  end
end
