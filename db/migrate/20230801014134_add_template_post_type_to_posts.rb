class AddTemplatePostTypeToPosts < ActiveRecord::Migration[7.0]
  def change
    add_reference :posts, :template_post_type, foreign_key: { to_table: :posts}
  end
end
