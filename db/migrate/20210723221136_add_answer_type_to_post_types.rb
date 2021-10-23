class AddAnswerTypeToPostTypes < ActiveRecord::Migration[5.2]
  def change
    add_reference :post_types, :answer_type, index: true, foreign_key: { to_table: :post_types }
  end
end
