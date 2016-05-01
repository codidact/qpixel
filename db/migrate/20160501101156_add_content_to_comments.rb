class AddContentToComments < ActiveRecord::Migration
  def change
    add_column :comments, :content, :string
  end
end
