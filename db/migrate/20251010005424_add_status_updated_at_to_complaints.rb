class AddStatusUpdatedAtToComplaints < ActiveRecord::Migration[7.2]
  def change
    add_column :complaints, :status_updated_at, :datetime
  end
end
