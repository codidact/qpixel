class Filter < ApplicationRecord
  belongs_to :user, required: true, class_name: 'User'
end
