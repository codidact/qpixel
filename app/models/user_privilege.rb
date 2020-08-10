class UserPrivilege < ApplicationRecord
  belongs_to :community_user
  belongs_to :trust_level
end
