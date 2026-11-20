class AddContentTypeToComplaints < ActiveRecord::Migration[7.2]
  def change
    add_column :complaints, :content_type, :string
  end
end
