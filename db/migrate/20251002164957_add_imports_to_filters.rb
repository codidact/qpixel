class AddImportsToFilters < ActiveRecord::Migration[7.2]
  def change
    add_column :filters, :imports, :string, null: false, default: :any
  end
end
