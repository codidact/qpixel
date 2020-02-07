# Represents a site setting. Site settings control the operation and display of most aspects of the site, such as
# reputation awards, additional content, and site constants such as name and logo.
class SiteSetting < ApplicationRecord
  belongs_to :community
  default_scope { for_community_id(RequestContext.community_id).or(global).priority_order }

  scope :for_community_id, ->(community_id){ where(community_id: community_id) }
  scope :global, ->{ for_community_id(nil) }
  scope :priority_order, -> { order(Arel::Nodes::Case.new.when(arel_table[:community_id].eq(nil), 1).else(0)) }

  validates :name, uniqueness: true

  def self.[](name)
    cached = Rails.cache.fetch "SiteSettings/#{name}" do
      SiteSetting.find_by(name: name)&.typed
    end
    cached.nil? ? SiteSetting.find_by(name: name)&.typed : cached # doubled to avoid cache fetch returning nil from cache
  end

  def self.exist?(name)
    Rails.cache.exist?("SiteSettings/#{name}") || SiteSetting.where(name: name).count > 0
  end

  def typed
    SettingConverter.new(value).send("as_#{value_type.downcase}")
  end
end

class SettingConverter
  def initialize(value)
    @value = value
  end

  def as_string
    @value&.to_s
  end

  def as_text
    @value&.to_s
  end

  def as_integer
    @value&.to_i
  end

  def as_float
    @value&.to_f
  end

  def as_boolean
    ActiveModel::Type::Boolean.new.cast(@value)
  end

  def as_json
    JSON.parse(@value)
  end
end
