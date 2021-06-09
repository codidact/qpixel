class ChangeFlagsReasonFieldType < ActiveRecord::Migration[5.2]
  def change
    change_column :flags, :reason, :text
  end
end
