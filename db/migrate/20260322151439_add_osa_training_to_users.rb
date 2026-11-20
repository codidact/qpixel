class AddOsaTrainingToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :osa_training, :datetime
  end
end
