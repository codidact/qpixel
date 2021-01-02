class ThreadFollower < ApplicationRecord
  belongs_to :comment_thread
  belongs_to :user
end
