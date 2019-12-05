class AddDefaultToAnswerCount < ActiveRecord::Migration[5.2]
  def change
    change_column :posts, :answer_count, :integer, default: 0, null: false
  end
end
