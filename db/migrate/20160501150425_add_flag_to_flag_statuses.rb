class AddFlagToFlagStatuses < ActiveRecord::Migration
  def change
    add_reference :flag_statuses, :flag, index: true, foreign_key: true
  end
end
