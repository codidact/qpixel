class AddBeforeColumnsToSuggestedEdit < ActiveRecord::Migration[5.2]
  def change
    add_column :suggested_edits, :before_title, :string
    add_column :suggested_edits, :before_body, :text
    add_column :suggested_edits, :before_body_markdown, :text
    add_column :suggested_edits, :before_tags_cache, :string

    create_table :suggested_edits_before_tags, id: false, primary_key: [:suggested_edit_id, :tag_id] do |t|
      t.bigint :suggested_edit_id, null: false
      t.bigint :tag_id, null: false
    end
  end
end
