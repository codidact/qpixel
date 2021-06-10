class AddRequiresDetailsToPostFlagTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :post_flag_types, :requires_details, :boolean, null: false, default: false
    PostFlagType.unscoped.where(name: ["needs author's attention", 'is a duplicate']).update_all(requires_details: true)
  end
end
