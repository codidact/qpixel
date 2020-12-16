class AddColumnsToPostType < ActiveRecord::Migration[5.2]
  def change
    change_table :post_types do |t|
      t.text :description
      t.boolean :has_answers, null: false, default: false
      t.boolean :has_votes, null: false, default: false
      t.boolean :has_tags, null: false, default: false
      t.boolean :has_parent, null: false, default: false
      t.boolean :has_category, null: false, default: false
      t.boolean :has_license, null: false, default: false
      t.boolean :is_public_editable, null: false, default: false
      t.boolean :is_closeable, null: false, default: false
      t.boolean :is_top_level, null: false, default: false
    end

    data = {
      'Question' => { has_answers: true, has_votes: true, has_tags: true, has_parent: false, has_category: true,
                      has_license: true, is_public_editable: true, is_closeable: true, is_top_level: true },
      'Answer' => { has_answers: false, has_votes: true, has_tags: false, has_parent: true, has_category: true,
                    has_license: true, is_public_editable: true, is_closeable: false, is_top_level: false },
      'HelpDoc' => { has_answers: false, has_votes: false, has_tags: false, has_parent: false, has_category: false,
                     has_license: false, is_public_editable: false, is_closeable: false, is_top_level: false },
      'PolicyDoc' => { has_answers: false, has_votes: false, has_tags: false, has_parent: false, has_category: false,
                       has_license: false, is_public_editable: false, is_closeable: false, is_top_level: false },
      'Article' => { has_answers: false, has_votes: true, has_tags: true, has_parent: false, has_category: true,
                     has_license: true, is_public_editable: false, is_closeable: false, is_top_level: true }
    }
    PostType.unscoped.all.each do |pt|
      pt.update(data[pt.name])
    end
  end
end
