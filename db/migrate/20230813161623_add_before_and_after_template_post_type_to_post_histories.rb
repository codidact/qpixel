class AddBeforeAndAfterTemplatePostTypeToPostHistories < ActiveRecord::Migration[7.0]
  def change
    add_reference :post_histories, :before_template_post_type, foreign_key: { to_table: :post_types }
    add_reference :post_histories, :after_template_post_type, foreign_key: { to_table: :post_types }
  end
end
