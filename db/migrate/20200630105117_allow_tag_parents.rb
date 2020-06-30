class AllowTagParents < ActiveRecord::Migration[5.2]
  def change
    add_reference :tags, :parent, foreign_key: { to_table: :tags }
  end
end
