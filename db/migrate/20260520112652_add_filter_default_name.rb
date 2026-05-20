class AddFilterDefaultName < ActiveRecord::Migration[7.2]
  def change
    change_column_default :filters, :name, ''
  end
end
