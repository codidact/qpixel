class CloseReasons < ActiveRecord::Migration[5.2]
  def change
    create_table :close_reasons do |t|
      t.string :name
      t.text :description
      t.boolean :active
      t.boolean :requires_other_post
    end
    add_reference :posts, :close_reasons, foreign_key: true, null: true
    add_reference :posts, :duplicate_post, foreign_key: {to_table: :posts}, null: true
  end
end
