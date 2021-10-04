class PostTypeSpecificReactions < ActiveRecord::Migration[5.2]
  def change
    add_reference :reaction_types, :post_type, null: true
    add_column :post_types, :has_only_specific_reactions, :boolean

    PostType.update_all(has_only_specific_reactions: false)
    PostType.where(name: ['Question']).update_all(has_only_specific_reactions: true)
  end
end
