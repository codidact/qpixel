class AddSourceToFilters < ActiveRecord::Migration[7.2]
  def change
    add_column :filters, :source, :string, null: false, default: :any
  end
end
