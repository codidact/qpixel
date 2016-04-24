class Question < ActiveRecord::Base
  belongs_to :user
  serialize :tags, Array
end
