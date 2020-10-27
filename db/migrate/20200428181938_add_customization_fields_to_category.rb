class AddCustomizationFieldsToCategory < ActiveRecord::Migration[5.2]
  def change
    change_table :categories do |t|
      t.string :color_code
    end
  end
end
