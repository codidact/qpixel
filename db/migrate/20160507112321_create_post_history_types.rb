class CreatePostHistoryTypes < ActiveRecord::Migration
  def change
    create_table :post_history_types do |t|
      t.string :name
      t.string :description
      t.string :action_name

      t.timestamps null: false
    end
  end
end
