class AddHasReactionsToPostTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :post_types, :has_reactions, :boolean
    PostType.update_all(has_reactions: false)
    PostType.where(name: ['Answer', 'Article']).update_all(has_reactions: true)
  end
end
