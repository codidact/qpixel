class Filter < ApplicationRecord
  belongs_to :user
  serialize :include_tags, Array
  serialize :exclude_tags, Array
end
