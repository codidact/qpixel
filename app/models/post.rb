class Post < ActiveRecord::Base
  belongs_to :user
  belongs_to :post_type
  belongs_to :parent, class_name: 'Post', required: false
  has_many :votes
  has_many :comments
  has_many :post_histories
  has_many :flags

  serialize :tags, Array

  validates :body, presence: true, length: { minimum: 30, maximum: 30000 }
end