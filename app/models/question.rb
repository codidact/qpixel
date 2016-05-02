# Represents a question. Questions are attached to a user account, and have many answers, a score, and can be voted on.
class Question < ActiveRecord::Base
  # By default, we only want to display non-deleted questions.
  default_scope { where(is_deleted: false) }

  # Attached to a user account.
  belongs_to :user

  # Can be answered.
  has_many :answers

  # Can be voted on as a Post.
  has_many :votes, :as => :post

  # Can be commented on as a Post.
  has_many :comments, :as => :post

  # Tags are not a string, they're a group of strings - sounds like an array to me.
  serialize :tags, Array

  # Can't be having questions without titles, bodies, or tags.
  validates :title, :body, :tags, :presence => true

  # It doesn't make sense to have 1-character posts, so let's have some minimums. And maximums, for that matter.
  validates :title, length: { minimum: 15, maximum: 255 }
  validates :body, length: { minimum: 30, maximum: 30000 }

  # Tags are not a string, but that does make validation a little irritating.
  validate :maximum_tags
  validate :maximum_tag_length

  validate :stripped_minimum

  private
    # Restricts the number of tags on any question to a maximum of 5, and a minimum of 1. This can't be achieved by any
    # of the standard validation helpers, since <tt>tags</tt> is an array.
    def maximum_tags
      if tags.length > 5
        errors.add(:tags, "can't have more than 5 tags")
      elsif tags.length < 1
        errors.add(:tags, "must have at least one tag")
      end
    end

    # Restricts the length of a single tag to 20 characters. This avoids styling issues with the
    # <tt>questions/question</tt> partial. Again, can't be done by regular validation helpers.
    def maximum_tag_length
      tags.each do |tag|
        if tag.length > 20
          errors.add(:tags, "can't be more than 20 characters long each")
        end
      end
    end

    # Verifies that the length of the body is over 30 characters after removing excessive whitespace characters.
    def stripped_minimum
      if body.squeeze(" 	").length < 30
        errors.add(:body, "must be more than 30 non-whitespace characters long")
      end
      if title.squeeze(" 	").length < 15
        errors.add(:title, "must be more than 15 non-whitespace characters long")
      end
    end
end
