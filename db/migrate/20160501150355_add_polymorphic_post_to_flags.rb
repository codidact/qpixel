class AddPolymorphicPostToFlags < ActiveRecord::Migration
  def change
    add_reference :flags, :post, polymorphic: true, index: true
  end
end
