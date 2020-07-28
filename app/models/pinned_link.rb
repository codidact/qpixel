class PinnedLink < ApplicationRecord
  include MaybeCommunityRelated
  belongs_to :post
end
