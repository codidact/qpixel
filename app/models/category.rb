class Category < ApplicationRecord
  include CommunityRelated

  has_many :category_post_types
  has_many :post_types, through: :category_post_types
  has_and_belongs_to_many :required_tags, class_name: 'Tag', join_table: 'categories_required_tags'
  has_and_belongs_to_many :topic_tags, class_name: 'Tag', join_table: 'categories_topic_tags'
  has_and_belongs_to_many :moderator_tags, class_name: 'Tag', join_table: 'categories_moderator_tags'
  has_many :posts
  belongs_to :tag_set
  belongs_to :license
  belongs_to :default_filter, class_name: 'Filter', optional: true

  serialize :display_post_types, coder: JSON, type: Array

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }

  def new_posts_for?(user)
    key = "#{community_id}/#{user.id}/#{id}/last_visit"
    Rails.cache.fetch key, expires_in: 5.minutes do
      Rack::MiniProfiler.step "Redis: category last visit (#{key})" do
        activity_key = "#{community_id}/#{id}/last_activity"
        last_visit = RequestContext.redis.get(key)
        last_activity = RequestContext.redis.get(activity_key) || DateTime.parse
        last_visit.nil? || last_activity > DateTime.parse(last_visit)
      end
    end
  end

  def update_activity(last_activity)
    RequestContext.redis.set("#{community_id}/#{id}/last_activity", last_activity)
  end

  def self.by_lowercase_name(name)
    categories = Rails.cache.fetch 'categories/by_lowercase_name' do
      Category.all.to_h { |c| [c.name.downcase, c] }
    end
    categories[name]
  end

  def self.by_id(id)
    categories = Rails.cache.fetch 'categories/by_id' do
      Category.all.to_h { |c| [c.id, c] }
    end
    categories[id]
  end
end
