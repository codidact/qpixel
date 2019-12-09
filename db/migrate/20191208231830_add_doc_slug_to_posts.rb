class AddDocSlugToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :doc_slug, :string
  end
end
