class AddEmailToComplaints < ActiveRecord::Migration[7.2]
  def change
    add_column :complaints, :email, :string
  end
end
