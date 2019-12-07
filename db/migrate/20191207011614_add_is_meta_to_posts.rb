class AddIsMetaToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :is_meta, :boolean, default: false
  end
end
