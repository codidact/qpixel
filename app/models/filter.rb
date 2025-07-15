class Filter < ApplicationRecord
  belongs_to :user
  has_many :category_filter_defaults, dependent: :destroy
  validates :name, uniqueness: { scope: :user }
  serialize :include_tags, coder: JSON, type: Array
  serialize :exclude_tags, coder: JSON, type: Array
end
