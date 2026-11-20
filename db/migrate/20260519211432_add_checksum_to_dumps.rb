class AddChecksumToDumps < ActiveRecord::Migration[7.2]
  def change
    add_column :dumps, :checksum, :string
  end
end
