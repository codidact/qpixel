class AddReportedUrlToComplaints < ActiveRecord::Migration[7.2]
  def change
    add_column :complaints, :reported_url, :string
  end
end
