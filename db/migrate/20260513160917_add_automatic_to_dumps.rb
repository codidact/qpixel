class AddAutomaticToDumps < ActiveRecord::Migration[7.2]
  def change
    add_column :dumps, :automatic, :boolean, null: false, default: false
  end
end
