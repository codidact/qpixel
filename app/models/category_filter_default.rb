class CategoryFilterDefault < ApplicationRecord
  belongs_to :user
  belongs_to :filter
  belongs_to :category
end
