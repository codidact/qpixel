class CreateFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :filters do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.float :min_score
      t.float :max_score
      t.integer :min_answers
      t.integer :max_answers
      t.string :status
      t.string :include_tags
      t.string :exclude_tags

      t.timestamps
    end
  end
end
