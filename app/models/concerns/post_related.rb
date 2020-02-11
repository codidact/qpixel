module PostRelated
  extend ActiveSupport::Concern
  include CommunityRelated

  included do
    belongs_to :post
  end
end
