# Represents a privilege. Privilege assignment is odd (see <tt>User#has_privilege?</tt>) - privileges are assigned
# lazily, rather than the moment a user crosses the threshold. Crossing the threshold does grant the privilege, since
# there's a backup rep check, but the privilege is not added to the user's privilege collection until they've been
# checked for it at least once.
class Privilege < ApplicationRecord
  has_and_belongs_to_many :users
end
