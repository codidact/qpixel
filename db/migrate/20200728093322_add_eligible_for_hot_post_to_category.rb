class AddEligibleForHotPostToCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :use_for_hot_posts, :boolean, default: true
    add_column :categories, :use_for_advertisement, :boolean, default: true
  end
end
