# Represents one answer. Answers are attached to both a question and a user account; have a score, and can be voted on.
class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :user

  has_many :votes, :as => :post
end
