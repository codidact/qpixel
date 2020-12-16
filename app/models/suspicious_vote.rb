class SuspiciousVote < ApplicationRecord
  belongs_to :from_user, class_name: 'User'
  belongs_to :to_user, class_name: 'User'

  validates :from_user, uniqueness: { scope: [:to_user] }

  def self.pending
    SuspiciousVote.where(was_investigated: false)
  end

  def self.check_for_vote_fraud
    User.all.find_each do |u|
      votes = u.votes.group(:recv_user_id).count(:recv_user_id)
      total = u.votes.count
      votes.each do |recv_id, cnt|
        cert = total.to_f / cnt.to_f**2
        if cert < 0.5 && recv_id != -1
          SuspiciousVote.create(from_user_id: u.id, to_user_id: recv_id, suspicious_count: cnt, total_count: total)
        end
      end
    end
  end
end
