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

  serialize :display_post_types, coder: YAML, type: Array

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }

  # Is the category set as the homepage?
  # @return [Boolean] check result
  def homepage?
    is_homepage == true
  end

  # Can anyone view the category (even if not logged in)?
  # @return [Boolean] check result
  def public?
    trust_level = min_view_trust_level || -1
    trust_level <= 0
  end

  def top_level_post_types
    post_types.where(is_top_level: true)
  end

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

  # Gets categories appropriately scoped for a given user
  # @param user [User] user to check
  # @return [ActiveRecord::Relation<category>]
  def self.accessible_to(user)
    if user&.at_least_moderator?
      return Category.all
    end

    trust_level = user&.trust_level || 0
    Category.where('IFNULL(min_view_trust_level, -1) <= ?', trust_level)
  end

  def self.by_lowercase_name(name)
    categories = Rails.cache.fetch 'categories/by_lowercase_name' do
      Category.all.to_h { |c| [c.name.downcase, c.id] }
    end
    Category.find_by(id: categories[name])
  end

  # @todo: Do we need this method?
  def self.by_id(id)
    categories = Rails.cache.fetch 'categories/by_id' do
      Category.all.to_h { |c| [c.id, c] }
    end
    categories[id]
  end

  def self.search(term)
    where('name LIKE ?', "%#{sanitize_sql_like(term)}%")
  end
end
