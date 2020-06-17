class ChangePostScoreColumnType < ActiveRecord::Migration[5.2]
  def change
    change_column :posts, :score, :decimal, precision: 10, scale: 8
  end
end
