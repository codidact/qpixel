class AddLinkToDumps < ActiveRecord::Migration[7.2]
  def change
    add_column :dumps, :link, :string
  end
end
