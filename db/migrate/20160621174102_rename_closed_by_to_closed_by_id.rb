class RenameClosedByToClosedById < ActiveRecord::Migration
  def change
    rename_column :questions, :closed_by, :closed_by_id
  end
end
