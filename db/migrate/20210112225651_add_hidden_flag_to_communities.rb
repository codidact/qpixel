class AddHiddenFlagToCommunities < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :hidden, :boolean, default: false
  end
end
