class DiallowFilterUserOrNameNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :filters, :user_id, false
    change_column_null :filters, :name, false
  end
end
