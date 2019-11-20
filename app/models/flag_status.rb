# Represents a flag status. Flag statuses are attached to a flag.
class FlagStatus < ApplicationRecord
  belongs_to :flag
end
