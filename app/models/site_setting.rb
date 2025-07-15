# Represents a site setting. Site settings control the operation and display of most aspects of the site, such as
# reputation awards, additional content, and site constants such as name and logo.
class SiteSetting < ApplicationRecord
  belongs_to :community, optional: true

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }

  scope :for_community_id, ->(community_id) { where(community_id: community_id) }
  scope :global, -> { for_community_id(nil) }
  scope :priority_order, -> { order(Arel.sql('IF(site_settings.community_id IS NULL, 1, 0)')) }

  def self.[](name)
    key = "SiteSettings/#{RequestContext.community_id}/#{name}"
    cached = Rails.cache.fetch key, include_community: false do
      SiteSetting.applied_setting(name)&.typed
    end

    if cached.nil?
      Rails.cache.delete key, include_community: false
      value = SiteSetting.applied_setting(name)&.typed
      Rails.cache.write key, value, include_community: false
      value
    else
      cached
    end
  end

  def self.[]=(name, value)
    key = "SiteSettings/#{RequestContext.community_id}/#{name}"

    setting = applied_setting(name)

    typed_value = SettingConverter.new(value).send("as_#{setting.value_type.downcase}")

    setting.update(value: typed_value)

    Rails.cache.write key, typed_value, include_community: false
  end

  def self.exist?(name)
    Rails.cache.exist?("SiteSettings/#{RequestContext.community_id}/#{name}", include_community: false) ||
      SiteSetting.where(name: name).any?
  end

  # Checks whether the setting is a global site setting
  # @return [Boolean]
  def global?
    community_id.nil?
  end

  # Is the setting boolean-valued?
  # @return [Boolena] check result
  def boolean?
    value_type.downcase == 'boolean'
  end

  # Is the setting floating point number-valued?
  # @return [Boolena] check result
  def float?
    value_type.downcase == 'float'
  end

  # Is the setting integer-valued?
  # @return [Boolena] check result
  def integer?
    value_type.downcase == 'integer'
  end

  # Is the setting string-valued (plain text)?
  # @return [Boolean] check result
  def string?
    value_type.downcase == 'string'
  end

  # Is the setting text-valued (HTML-aware text)?
  # @return [Boolean] check result
  def text?
    value_type.downcase == 'text'
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
    cached = Rails.cache.read_multi(*keys.values, include_community: false)
    missing = keys.reject { |_k, v| cached.include?(v) }.map { |k, _v| k }
    settings = if missing.empty?
                 {}
               else
                 SiteSetting.where(name: name, community_id: missing).to_h { |s| [s.community_id, s] }
               end
    Rails.cache.write_multi(missing.to_h { |cid| [keys[cid], settings[cid]&.typed] }, include_community: false)
    communities.to_h do |c|
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
    end
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
