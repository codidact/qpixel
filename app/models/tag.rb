class Tag < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :posts
  belongs_to :tag_set
end
