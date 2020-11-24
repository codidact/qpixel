class RenameAbilityTables < ActiveRecord::Migration[5.2]
  def change
    rename_table :trust_levels, :abilities
    rename_table :user_privileges, :user_abilities
    rename_column :user_abilities, :trust_level_id, :ability_id
  end
end
