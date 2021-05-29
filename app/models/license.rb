class License < ApplicationRecord
  include CommunityRelated

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  validates :name, uniqueness: { scope: [:community_id] }

  def self.default_order(category = nil, user_default = nil)
    if category.present? && user_default.present?
      License.all.order(Arel.sql(sanitize_sql_array(['name = ? DESC', user_default])))
             .order(Arel.sql(sanitize_sql_array(['id = ? DESC', category.license_id])))
             .order(default: :desc)
    elsif user_default.present?
      License.all.order(Arel.sql(sanitize_sql_array(['name = ? DESC', user_default])))
             .order(default: :desc)
    elsif category.present?
      License.all.order(Arel.sql(sanitize_sql_array(['id = ? DESC', category.license_id])))
             .order(default: :desc)
    else
      License.all.order(default: :desc)
    end.order(name: :asc)
  end

  def self.site_default
    License.where(default: true).first
  end
end
