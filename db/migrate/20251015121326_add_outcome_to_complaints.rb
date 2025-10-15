class AddOutcomeToComplaints < ActiveRecord::Migration[7.2]
  def change
    add_column :complaints, :outcome, :string
  end
end
