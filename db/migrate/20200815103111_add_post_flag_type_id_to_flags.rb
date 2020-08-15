class AddPostFlagTypeIdToFlags < ActiveRecord::Migration[5.2]
  def change
    add_reference :flags, :post_flag_types
  end
end
