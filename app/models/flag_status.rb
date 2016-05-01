# Represents a flag status. Flag statuses are attached to a flag.
class FlagStatus < ActiveRecord::Base
  belongs_to :flag
end
