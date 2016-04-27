# Represents a question. Questions are attached to a user account, and have many answers, a score, and can be voted on.
class Question < ActiveRecord::Base
  belongs_to :user

  has_many :answers
  has_many :votes, :as => :post

  serialize :tags, Array

  validates :title, :body, :tags, :presence => true
  validates :title, length: { minimum: 15, maximum: 255 }
  validates :body, length: { minimum: 30, maximum: 30000 }
  validate :maximum_tags
  validate :maximum_tag_length

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
end
