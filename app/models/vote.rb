# Represents a vote. A vote is attached to both a 'post' (i.e. a question or an answer - this is a polymorphic
# association), and to a user.
class Vote < ApplicationRecord
  belongs_to :post
  belongs_to :user
end
