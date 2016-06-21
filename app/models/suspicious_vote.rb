class SuspiciousVote < ActiveRecord::Base
  belongs_to :from_user, :foreign_key => "from_user", :class_name => "User"
  belongs_to :to_user, :foreign_key => "to_user", :class_name => "User"

  validates :from_user, uniqueness: { scope: [:to_user] }

  def self.pending
    SuspiciousVote.where(:was_investigated => false)
  end

  def self.check_for_vote_fraud
    User.all.each do |u|
      votes = u.votes.group(:recv_user).count(:recv_user)
      total = u.votes.count
      votes.each do |recv_id, cnt|
        cert = total.to_f / cnt.to_f ** 2
        if cert < 0.5 && recv_id != -1
          puts "#{u.id} => #{recv_id} suspicious (#{cnt}/#{total}) (#{cert})"
          sv = SuspiciousVote.new
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
