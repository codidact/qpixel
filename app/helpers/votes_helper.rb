# Provides helper methods for use by views under <tt>VotesController</tt>.
module VotesHelper
  def self.check_for_vote_fraud
    User.all.each do |u|
      votes = u.votes.group(:recv_user).count(:recv_user)
      total = u.votes.count
      votes.each do |recv_id, cnt|
        if (total / cnt**2) < 0.5 && recv_id != -1
          sv = SuspiciousVotes.new
          sv.from_user = u.id
          sv.to_user = recv_id
          sv.suspicious_count = cnt
          sv.total_count = total
          sv.save
        end
      end
    end
  end
end
