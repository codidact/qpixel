class AddHelpAttributesToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :help_category, :string
    add_column :posts, :help_ordering, :integer
  end
end
