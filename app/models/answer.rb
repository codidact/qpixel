# Represents one answer. Answers are attached to both a question and a user account; have a score, and can be voted on.
class Answer < ActiveRecord::Base
  # Attached to a question, otherwise it'll never display anywhere.
  belongs_to :question

  # Attached to a user account.
  belongs_to :user

  # Can be voted on as a Post.
  has_many :votes, :as => :post

  # Can't be having answers without bodies.
  validates :body, :presence => true

  # 1-character answers aren't really answers, so let's set some limits.
  validates :body, length: { minimum: 30, maximum: 30000 }
end
