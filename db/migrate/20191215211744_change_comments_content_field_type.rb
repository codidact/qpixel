class ChangeCommentsContentFieldType < ActiveRecord::Migration[5.2]
  def change
    change_column :comments, :content, :text
  end
end
