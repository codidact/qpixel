class AddTagsToFilters < ActiveRecord::Migration[7.0]
  def change
    add_column :filters, :include_tags, :string
    add_column :filters, :exclude_tags, :string
  end
end
