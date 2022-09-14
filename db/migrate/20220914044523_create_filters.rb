class CreateFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :filters do |t|
      t.references :user, foreign_key: true
      t.string :name
      t.float :min_score
      t.float :max_score
      t.integer :min_answers
      t.integer :max_answers
      t.string :status

      t.timestamps
    end
  end
end
