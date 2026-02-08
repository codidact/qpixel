class Subscription < ApplicationRecord
  include CommunityRelated
  include Timestamped

  self.inheritance_column = 'sti_type'

  BASE_TYPES = ['all', 'tag', 'user', 'interesting', 'category'].freeze
  MOD_ONLY_TYPES = ['moderators'].freeze
  TYPES = (BASE_TYPES + MOD_ONLY_TYPES).freeze
  QUALIFIED_TYPES = ['category', 'tag', 'user'].freeze

  belongs_to :user

  validates :type, presence: true, inclusion: TYPES
  validates :frequency, numericality: { minimum: 1, maximum: 90 }

  validate :qualifier_presence

  # Gets a list of subscription types available to a given user
  # @param user [User] user to check type access for
  # @return [Array<String>] list of available types
  def self.types_accessible_to(user)
    user.at_least_moderator? ? TYPES : BASE_TYPES
  end

  def questions
    case type
    when 'all'
      Question.unscoped.on(community).where(post_type_id: Question.post_type_id)
              .where(Question.arel_table[:created_at].gteq(last_sent_at || created_at))
    when 'tag'
      Question.unscoped.on(community).where(post_type_id: Question.post_type_id)
              .where(Question.arel_table[:created_at].gteq(last_sent_at || created_at))
              .joins(:tags).where(tags: { name: qualifier })
    when 'user'
      Question.unscoped.on(community).where(post_type_id: Question.post_type_id)
              .where(Question.arel_table[:created_at].gteq(last_sent_at || created_at))
              .where(user_id: qualifier)
    when 'interesting'
      Question.unscoped.on(community).where(post_type_id: Question.post_type_id)
              .where('score >= ?', interesting_threshold)
              .order(Arel.sql('RAND()'))
    when 'category'
      Question.unscoped.on(community).where(post_type_id: Question.post_type_id)
              .where(Question.arel_table[:created_at].gteq(last_sent_at || created_at))
              .where(category_id: qualifier)
    end&.order(created_at: :desc)&.limit(25)
  end

  # Is the subscription's type qualified (bound to an entity)?
  # @param type [String] type to check
  # @return [Boolean] check result
  def qualified?
    QUALIFIED_TYPES.include?(type)
  end

  # Gets entity bound to the subscription through qualifier, if any
  # @return [Category, Tag, User, nil]
  def qualifier_entity
    if qualified? && qualifier.present?
      model = type.singularize.classify.constantize
      tag? ? model.find_by(name: qualifier) : model.find(qualifier)
    end
  end

  # Gets name of the entity bound to the subscription through qualifier, if any
  # @return [String]
  def qualifier_name
    qualifier_entity&.name || qualifier
  end

  # Predicates for each of the available type (f.e., user?)
  TYPES.each do |type_name|
    define_method "#{type_name}?" do
      type == type_name
    end
  end

  private

  def interesting_threshold
    SiteSetting.applied_setting('InterestingSubscriptionScoreThreshold', community: community).typed
  end

  def qualifier_presence
    return unless qualified?

    if type == 'tag' && (qualifier.blank? || Tag.find_by(name: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid tag name for tag subscriptions')
    elsif type == 'user' && (qualifier.blank? || User.find_by(id: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid user ID for user subscriptions')
    elsif type == 'category' && (qualifier.blank? || Category.find_by(id: qualifier).nil?)
      errors.add(:qualifier, 'must provide a valid category ID for category subscriptions')
    end
  end
end
