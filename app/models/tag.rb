class Tag < ApplicationRecord
  has_and_belongs_to_many :posts
end
