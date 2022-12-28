class Filter < ApplicationRecord
  belongs_to :user
  validates :name, uniqueness: { scope: :user }
  serialize :include_tags, Array
  serialize :exclude_tags, Array
end
