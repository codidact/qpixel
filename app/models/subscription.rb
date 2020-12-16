class Subscription < ApplicationRecord
  self.inheritance_column = 'sti_type'

  include CommunityRelated

  belongs_to :user

  validates :type, presence: true, inclusion: ['all', 'tag', 'user', 'interesting', 'category', 'moderators']
  validates :frequency, numericality: { minimum: 1, maximum: 90 }

  validate :qualifier_presence

  def questions
    case type
    when 'all'
      Question.unscoped.where(community: community, post_type_id: Question.post_type_id)
              .where('created_at >= ?', last_sent_at)
    when 'tag'
      Question.unscoped.where(community: community, post_type_id: Question.post_type_id)
              .joins(:tags).where(tags: { name: qualifier })
    when 'user'
      Question.unscoped.where(community: community, post_type_id: Question.post_type_id)
              .where(user_id: qualifier)
    when 'interesting'
      RequestContext.community = community # otherwise SiteSetting#[] doesn't work
      Question.unscoped.where(community: community, post_type_id: Question.post_type_id)
              .where('score >= ?', SiteSetting['InterestingSubscriptionScoreThreshold'])
              .order(Arel.sql('RAND()'))
    when 'category'
      Question.unscoped.where(community: community, post_type_id: Question.post_type_id)
              .where(category_id: qualifier)
    end&.order(created_at: :desc)&.limit(25)
  end

  private

  def qualifier_presence
    return unless ['tag', 'user', 'category'].include? type

    if type == 'tag' && (qualifier.blank? || Tag.find_by(name: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid tag name for tag subscriptions')
    elsif type == 'user' && (qualifier.blank? || User.find_by(id: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid user ID for user subscriptions')
    elsif type == 'category' && (qualifier.blank? || Category.find_by(id: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid category ID for category subscriptions')
    end
  end
end
