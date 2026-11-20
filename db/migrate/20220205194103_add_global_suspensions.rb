class AddGlobalSuspensions < ActiveRecord::Migration[5.2]
  def change
    add_column :warnings, :is_global, :boolean, default: false
    add_column :users, :is_globally_suspended, :boolean, default: false
    add_column :users, :global_suspension_end, :datetime
  end
end
