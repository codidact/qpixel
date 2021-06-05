class AddFakeCommunityOption < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :is_fake, :boolean, default: false
  end
end
