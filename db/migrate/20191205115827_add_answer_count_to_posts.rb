class AddAnswerCountToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :answer_count, :integer
  end
end
