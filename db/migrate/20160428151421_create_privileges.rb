class CreatePrivileges < ActiveRecord::Migration
  def change
    create_table :privileges do |t|

      t.timestamps null: false
    end
  end
end
