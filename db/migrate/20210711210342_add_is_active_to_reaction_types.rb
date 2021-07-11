class AddIsActiveToReactionTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :reaction_types, :active, :boolean
    ReactionType.unscoped.all.update_all(active: true)
  end
end
