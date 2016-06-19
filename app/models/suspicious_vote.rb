class SuspiciousVote < ActiveRecord::Base
  def self.pending
    SuspiciousVote.where(:was_investigated => false)
  end
end
