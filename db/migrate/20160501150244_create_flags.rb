class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.string :reason

      t.timestamps null: false
    end
  end
end
