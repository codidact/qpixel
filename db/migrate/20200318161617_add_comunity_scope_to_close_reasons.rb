class AddComunityScopeToCloseReasons < ActiveRecord::Migration[5.2]
  def change
    change_table :close_reasons do |t|
      t.references :community
    end
  end
end
