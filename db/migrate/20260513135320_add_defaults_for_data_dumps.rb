class AddDefaultsForDataDumps < ActiveRecord::Migration[7.2]
  def change
    # Add a bunch of default values for NOT NULL columns that don't already have them, so that data dumps don't break
    # when the data in these columns isn't included. Only applies to NOT NULL columns that are NOT included in the dump,
    # and do not already have a default value.
    change_column_default :filters, :user_id, -1
    change_column_default :flags, :escalated, false
    change_column_default :users, :sign_in_count, 0
    change_column_default :users, :failed_attempts, 0
    change_column_default :users, :deleted, false
  end
end
