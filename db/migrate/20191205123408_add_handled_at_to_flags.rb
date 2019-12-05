class AddHandledAtToFlags < ActiveRecord::Migration[5.2]
  def change
    add_column :flags, :handled_at, :datetime
  end
end
