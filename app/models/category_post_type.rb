class CategoryPostType < ApplicationRecord
  self.table_name = 'categories_post_types'

  belongs_to :category
  belongs_to :post_type

  def self.rep_changes
    Rails.cache.fetch 'network/category_post_types/rep_changes', include_community: false do
      all.map { |cpt| [[cpt.category_id, cpt.post_type_id], { 1 => cpt.upvote_rep, -1 => cpt.downvote_rep }] }.to_h
    end
  end
end
