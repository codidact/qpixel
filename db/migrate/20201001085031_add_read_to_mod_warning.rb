class AddReadToModWarning < ActiveRecord::Migration[5.2]
  def change
    add_column :warnings, :read, :boolean, default: false
  end
end
