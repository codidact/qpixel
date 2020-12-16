class CreateTrustLevels < ActiveRecord::Migration[5.2]
  def change
    create_table :trust_levels do |t|
      t.references :community, foreign_key: true
      t.string :name
      t.text :description
      t.string :internal_id
      t.string :icon
      t.decimal :post_score_threshold, null: true, precision: 10, scale: 8
      t.decimal :edit_score_threshold, null: true, precision: 10, scale: 8
      t.decimal :flag_score_threshold, null: true, precision: 10, scale: 8
      t.timestamps
    end
  end
end
