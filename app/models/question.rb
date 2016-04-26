# Represents a question. Questions are attached to a user account, and have many answers, a score, and can be voted on.
class Question < ActiveRecord::Base
  belongs_to :user

  has_many :answers
  has_many :votes, :as => :post

  serialize :tags, Array

  validates :title, :body, :tags, :presence => true
end
