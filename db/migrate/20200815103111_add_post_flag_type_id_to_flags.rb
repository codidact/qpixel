class AddPostFlagTypeIdToFlags < ActiveRecord::Migration[5.2]
  def change
    add_reference :flags, :post_flag_type, null: true
  end
end
