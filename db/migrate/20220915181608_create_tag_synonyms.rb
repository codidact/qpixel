class CreateTagSynonyms < ActiveRecord::Migration[7.0]
  def change
    create_table :tag_synonyms do |t|
      t.belongs_to :tag, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
  end
end
