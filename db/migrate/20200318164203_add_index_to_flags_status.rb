class AddIndexToFlagsStatus < ActiveRecord::Migration[5.2]
  def change
    add_index :flags, :status
  end
end
