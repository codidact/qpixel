# Represents a site setting. Site settings control the operation and display of most aspects of the site, such as
# reputation awards, additional content, and site constants such as name and logo.
class SiteSetting < ApplicationRecord
  belongs_to :community

  validates :name, uniqueness: { scope: [:community_id] }

  scope :for_community_id, ->(community_id) { where(community_id: community_id) }
  scope :global, -> { for_community_id(nil) }
  scope :priority_order, -> { order(Arel.sql('IF(site_settings.community_id IS NULL, 1, 0)')) }

  def self.[](name)
    key = "SiteSettings/#{RequestContext.community_id}/#{name}"
    cached = Rails.cache.fetch key do
      SiteSetting.applied_setting(name)&.typed
    end

    if cached.nil?
      Rails.cache.delete key
      value = SiteSetting.applied_setting(name)&.typed
      Rails.cache.write key, value
      value
    else
      cached
    end
  end

  def self.exist?(name)
    Rails.cache.exist?("SiteSettings/#{RequestContext.community_id}/#{name}") ||
      SiteSetting.where(name: name).count.positive?
  end

  def typed
    SettingConverter.new(value).send("as_#{value_type.downcase}")
  end

  def self.typed(setting)
    SettingConverter.new(setting.value).send("as_#{setting.value_type.downcase}")
  end

  def self.applied_setting(name)
    SiteSetting.for_community_id(RequestContext.community_id).or(global).where(name: name).priority_order.first
  end

  def self.all_communities(name)
    communities = Community.all
    keys = (communities.map { |c| [c.id, "SiteSetting/#{c.id}/#{name}"] } + [[nil, "SiteSetting//#{name}"]]).to_h
    cached = Rails.cache.read_multi(*keys.values)
    missing = keys.reject { |_k, v| cached.include?(v) }.map { |k, _v| k }
    settings = if missing.empty?
                 {}
               else
                 SiteSetting.where(name: name, community_id: missing).map { |s| [s.community_id, s] }.to_h
               end
    Rails.cache.write_multi missing.map { |cid| [keys[cid], settings[cid]&.typed] }.to_h
    communities.map do |c|
      [
        c.id,
        if cached.include?(keys[c.id])
          cached[keys[c.id]]
        elsif settings.include?(c.id)
          settings[c.id]&.typed
        elsif cached.include?(keys[nil])
          cached[keys[nil]]
        elsif settings.include?(nil)
          settings[nil]&.typed
        end
      ]
    end.to_h
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
