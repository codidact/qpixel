class CreateDumps < ActiveRecord::Migration[7.2]
  def change
    create_table :dumps do |t|
      t.timestamps
    end
  end
end
