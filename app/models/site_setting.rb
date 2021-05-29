# Represents a site setting. Site settings control the operation and display of most aspects of the site, such as
# reputation awards, additional content, and site constants such as name and logo.
class SiteSetting < ApplicationRecord
  belongs_to :community

  validates :name, uniqueness: { scope: [:community_id] }

  scope :for_community_id, ->(community_id) { where(community_id: community_id) }
  scope :global, -> { for_community_id(nil) }
  scope :priority_order, -> { order(Arel.sql('IF(site_settings.community_id IS NULL, 1, 0)')) }

  def self.[](name)
    cached = Rails.cache.fetch "SiteSettings/#{RequestContext.community_id}/#{name}" do
      SiteSetting.applied_setting(name)&.typed
    end
    # applied_setting call is doubled to avoid cache fetch returning nil from cache
    cached.nil? ? SiteSetting.applied_setting(name)&.typed : cached
  end

  def self.exist?(name)
    Rails.cache.exist?("SiteSettings/#{RequestContext.community_id}/#{name}") ||
      SiteSetting.where(name: name).count.positive?
  end

  def typed
    SettingConverter.new(value).send("as_#{value_type.downcase}")
  end

  def self.applied_setting(name)
    SiteSetting.for_community_id(RequestContext.community_id).or(global).where(name: name).priority_order.first
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
