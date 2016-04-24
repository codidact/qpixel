class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :title
      t.string :body
      t.text :tags
      t.integer :score

      t.timestamps null: false
    end
  end
end
