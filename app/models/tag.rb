class Tag < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :posts
end
