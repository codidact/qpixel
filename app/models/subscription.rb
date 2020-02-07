class Subscription < ApplicationRecord
  self.inheritance_column = 'sti_type'

  include CommunityRelated

  belongs_to :user

  validates :type, presence: true, inclusion: ['all', 'tag', 'user', 'interesting']
  validates :frequency, numericality: { minimum: 1, maximum: 90 }

  validate :qualifier_presence

  def questions
    case self.type
    when 'all'
      Question.where('created_at >= ?', last_sent_at)
    when 'tag'
      Tag.find_by(name: self.qualifier)&.posts
    when 'user'
      User.find_by(id: self.qualifier)&.questions
    when 'interesting'
      Question.where('score >= ?', SiteSetting['InterestingSubscriptionScoreThreshold'])
              .order(Arel.sql('RAND()'))
    else
      nil
    end&.order(created_at: :desc)&.limit(100)
  end

  private

  def qualifier_presence
    return unless ['tag', 'user'].include? type

    if type == 'tag' && (!qualifier.present? || Tag.find_by(name: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid tag name for tag subscriptions')
    elsif type == 'user' && (!qualifier.present? || User.find_by(id: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid user ID for user subscriptions')
    end
  end
end
