# Represents one answer. Answers are attached to both a question and a user account; have a score, and can be voted on.
class Answer < ActiveRecord::Base
  default_scope { where(:is_deleted => false) }

  # Attached to a question, otherwise it'll never display anywhere.
  belongs_to :question

  # Attached to a user account.
  belongs_to :user

  # Can be voted on as a Post.
  has_many :votes, :as => :post

  # Can be commented on as a Post.
  has_many :comments, :as => :post

  # Can't be having answers without bodies.
  validates :body, :presence => true

  # 1-character answers aren't really answers, so let's set some limits.
  validates :body, length: { minimum: 30, maximum: 30000 }

  validate :stripped_minimum

  private
    # Verifies that the length of the body is over 30 characters after removing excessive whitespace characters.
    def stripped_minimum
      if body.squeeze(" 	").length < 30
        errors.add(:body, "must be more than 30 non-whitespace characters long")
      end
    end
end
