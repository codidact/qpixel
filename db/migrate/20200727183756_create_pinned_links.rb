class CreatePinnedLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :pinned_links do |t|
      t.references :community, null: true, foreign_key: true
      t.string :label, null: true
      t.string :link, null: true
      t.references :post, null: true, foreign_key: true
      t.boolean :active
      t.datetime :shown_after, null: true
      t.datetime :shown_before, null: true
      t.timestamps
    end
  end
end
