# Represents a site setting. Site settings control the operation and display of most aspects of the site, such as
# reputation awards, additional content, and site constants such as name and logo.
class SiteSetting < ApplicationRecord
  belongs_to :community, optional: true

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }

  scope :for_community_id, ->(community_id) { where(community_id: community_id) }
  scope :global, -> { for_community_id(nil) }
  scope :priority_order, -> { order(Arel.sql('IF(site_settings.community_id IS NULL, 1, 0)')) }

  serialize :options, coder: YAML, type: Array

  def self.[](name, community: nil)
    key = "SiteSettings/#{community.present? ? community.id : RequestContext.community_id}/#{name}"
    cached = Rails.cache.fetch key, include_community: false do
      SiteSetting.applied_setting(name, community: community)&.typed
    end

    if cached.nil?
      Rails.cache.delete key, include_community: false
      value = SiteSetting.applied_setting(name, community: community)&.typed
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

  # Is the setting global?
  # @return [Boolean] check result
  def global?
    community_id.nil?
  end

  # Defines predicates for each value type
  [:array, :boolean, :float, :integer, :string, :text].each do |method|
    define_method "#{method}?" do
      value_type.downcase.to_sym == method
    end
  end

  # Is the setting numeric-valued?
  # @return [Boolean] check result
  def numeric?
    float? || integer?
  end

  def typed
    SettingConverter.new(value).send("as_#{value_type.downcase}")
  end

  def self.typed(setting)
    SettingConverter.new(setting.value).send("as_#{setting.value_type.downcase}")
  end

  def self.applied_setting(name, community: nil)
    SiteSetting.for_community_id(community.present? ? community.id : RequestContext.community_id)
               .or(global).where(name: name).priority_order.first
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
