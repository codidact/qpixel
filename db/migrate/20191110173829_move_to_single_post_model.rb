class MoveToSinglePostModel < ActiveRecord::Migration[5.0]
  def change
    create_table :post_types do |t|
      t.string :name
    end

    types = PostType.all.map(&:name)
    unless ['Question', 'Answer'].all? { |n| types.include? n }
      PostType.create([{ id: 1, name: 'Question' }, { id: 2, name: 'Answer' }])
    end

    create_table :posts do |t|
      t.integer :post_type_id, null: false
      t.string :title
      t.text :body, null: false
      t.string :tags
      t.integer :score, null: false, default: 0
      t.integer :parent_id
      t.integer :user_id
      t.boolean :closed
      t.integer :closed_by_id
      t.datetime :closed_at
      t.boolean :deleted
      t.integer :deleted_by_id
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
