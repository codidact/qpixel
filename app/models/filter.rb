class Filter < ApplicationRecord
  belongs_to :user
  has_many :category_filter_defaults, dependent: :destroy
  validates :name, uniqueness: { scope: :user }
  serialize :include_tags, Array
  serialize :exclude_tags, Array
end
