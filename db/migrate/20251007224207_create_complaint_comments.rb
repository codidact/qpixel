class CreateComplaintComments < ActiveRecord::Migration[7.2]
  def change
    create_table :complaint_comments do |t|
      t.references :complaint, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.text :content, null: false
      t.boolean :internal, null: false

      t.timestamps
    end
  end
end
