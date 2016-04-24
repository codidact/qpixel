class Question < ActiveRecord::Base
  serialize :tags, Array
end
