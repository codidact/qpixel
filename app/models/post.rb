class Post < ApplicationRecord
  include CommunityRelated

  belongs_to :user
  belongs_to :post_type
  belongs_to :parent, class_name: 'Post', optional: true
  belongs_to :closed_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  belongs_to :last_activity_by, class_name: 'User', optional: true
  belongs_to :locked_by, class_name: 'User', optional: true
  belongs_to :last_edited_by, class_name: 'User', optional: true
  belongs_to :category, optional: true
  belongs_to :license, optional: true
  belongs_to :close_reason, optional: true
  belongs_to :duplicate_post, class_name: 'Question', optional: true
  has_and_belongs_to_many :tags, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :comment_threads, dependent: :destroy
  has_many :post_histories, dependent: :destroy
  has_many :flags, as: :post, dependent: :destroy
  has_many :children, class_name: 'Post', foreign_key: 'parent_id', dependent: :destroy
  has_many :suggested_edits, dependent: :destroy

  counter_culture :parent, column_name: proc { |model| model.deleted? ? nil : 'answer_count' }

  serialize :tags_cache, Array

  validates :body, presence: true, length: { minimum: 30, maximum: 30_000 }
  validates :doc_slug, uniqueness: { scope: [:community_id] }, if: -> { doc_slug.present? }
  validates :title, :body, :tags_cache, presence: true, if: -> { post_type.has_tags }
  validate :tags_in_tag_set, if: -> { post_type.has_tags }
  validate :maximum_tags, if: -> { post_type.has_tags }
  validate :maximum_tag_length, if: -> { post_type.has_tags }
  validate :no_spaces_in_tags, if: -> { post_type.has_tags }
  validate :stripped_minimum, if: -> { post_type.has_tags }
  validate :category_allows_post_type, if: -> { category_id.present? }
  validate :license_valid, if: -> { post_type.has_license }
  validate :required_tags?, if: -> { post_type.has_tags && post_type.has_category }
  validate :moderator_tags, if: -> { post_type.has_tags && post_type.has_category }

  scope :undeleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }
  scope :qa_only, -> { where(post_type_id: [Question.post_type_id, Answer.post_type_id, Article.post_type_id]) }
  scope :list_includes, lambda {
                          includes(:user, :tags, :post_type, :category, :last_activity_by,
                                   user: :avatar_attachment)
                        }

  before_validation :update_tag_associations, if: -> { post_type.has_tags }
  after_create :create_initial_revision
  after_save :check_attribution_notice
  after_save :modify_author_reputation
  after_save :copy_last_activity_to_parent
  after_save :break_description_cache
  after_save :update_category_activity, if: -> { post_type.has_category }
  after_save :recalc_score

  def self.search(term)
    match_search term, posts: :body_markdown
  end

  # Double-define: initial definitions are less efficient, so if we have a record of the post type we'll
  # override them later with more efficient methods.
  ['Question', 'Answer', 'PolicyDoc', 'HelpDoc', 'Article'].each do |pt|
    define_method "#{pt.underscore}?" do
      post_type_id == pt.constantize.post_type_id
    end
  end

  PostType.all.find_each do |pt|
    define_method "#{pt.name.underscore}?" do
      post_type_id == pt.id
    end
  end

  def tag_set
    parent.nil? ? category.tag_set : parent.category.tag_set
  end

  def meta?
    false
  end

  def reassign_user(new_user)
    new_user.ensure_community_user!

    # Three updates: one to remove rep from previous user, one to reassign, one to re-grant rep to new user
    update!(deleted: true, deleted_at: DateTime.now, deleted_by: User.find(-1))
    update!(user: new_user)
    votes.update_all(recv_user_id: new_user.id)
    update!(deleted: false, deleted_at: nil, deleted_by: nil)
  end

  def remove_attribution_notice!
    update(att_source: nil, att_license_link: nil, att_license_name: nil)
  end

  def body_plain
    ApplicationController.helpers.strip_markdown(body_markdown)
  end

  def question?
    post_type_id == Question.post_type_id
  end

  def answer?
    post_type_id == Answer.post_type_id
  end

  def article?
    post_type_id == Article.post_type_id
  end

  def pending_suggested_edit?
    SuggestedEdit.where(post_id: id, active: true).any?
  end

  def pending_suggested_edit
    SuggestedEdit.where(post_id: id, active: true).last
  end

  def recalc_score
    variable = SiteSetting['ScoringVariable'] || 2
    sql = 'UPDATE posts SET score = (upvote_count + ?) / (upvote_count + downvote_count + (2 * ?)) WHERE id = ?'
    sanitized = ActiveRecord::Base.sanitize_sql_array([sql, variable, variable, id])
    ActiveRecord::Base.connection.execute sanitized
  end

  def locked?
    return true if locked && locked_until.nil? # permanent lock
    return true if locked && !locked_until.past?

    if locked
      update(locked: false, locked_by: nil, locked_at: nil, locked_until: nil)
    end
  end

  def can_access?(user)
    (!deleted? || user&.has_post_privilege?('flag_curate', self)) &&
      (!category.present? || !category.min_view_trust_level.present? ||
        category.min_view_trust_level <= (user&.trust_level || 0))
  end

  private

  def update_tag_associations
    tags_cache.each do |tag_name|
      tag = Tag.find_or_create_by name: tag_name, tag_set: category.tag_set
      unless tags.include? tag
        tags << tag
      end
    end
    tags.each do |tag|
      unless tags_cache.include? tag.name
        tags.delete tag
      end
    end
  end

  def attribution_text(source = nil, name = nil, url = nil)
    "Source: #{source || att_source}\nLicense name: #{name || att_license_name}\n" \
      "License URL: #{url || att_license_link}"
  end

  def check_attribution_notice
    sc = saved_changes
    attributes = ['att_source', 'att_license_name', 'att_license_link']
    if attributes.any? { |x| sc.include?(x) && sc[x][0] != sc[x][1] }
      if attributes.all? { |x| sc[x]&.try(:[], 0).nil? }
        PostHistory.attribution_notice_added(self, User.find(-1), after: attribution_text)
      elsif attributes.all? { |x| sc[x]&.try(:[], 1).nil? }
        PostHistory.attribution_notice_removed(self, User.find(-1),
                                               before: attribution_text(*attributes.map { |a| sc[a]&.try(:[], 0) }))
      else
        PostHistory.attribution_notice_changed(self, User.find(-1),
                                               before: attribution_text(*attributes.map { |a| sc[a]&.try(:[], 0) }),
                                               after: attribution_text(*attributes.map { |a| sc[a]&.try(:[], 1) }))
      end
    end
  end

  def copy_last_activity_to_parent
    sc = saved_changes
    if parent.present? && (sc.include?('last_activity') || sc.include?('last_activity_by_id')) \
       && !parent.update(last_activity: last_activity, last_activity_by: last_activity_by)
      Rails.logger.error "Parent failed copy_last_activity update (#{parent.errors.full_messages.join(';')})"
    end
  end

  def modify_author_reputation
    sc = saved_changes
    if sc.include?('deleted') && sc['deleted'][0] != sc['deleted'][1] && created_at >= 60.days.ago
      deleted = !!saved_changes['deleted']&.last
      if deleted
        user.update(reputation: user.reputation - Vote.total_rep_change(votes))
      else
        user.update(reputation: user.reputation + Vote.total_rep_change(votes))
      end
    end
  end

  def create_initial_revision
    PostHistory.initial_revision(self, user, after: body_markdown, after_title: title, after_tags: tags)
  end

  def category_allows_post_type
    return if category.nil?

    unless category&.post_types&.include? post_type
      errors.add(:base, "The #{post_type.name} post type is not allowed in the #{category&.name} category.")
    end
  end

  def break_description_cache
    Rails.cache.delete "posts/#{id}/description"
    if parent_id.present?
      Rails.cache.delete "posts/#{parent_id}/description"
    end
  end

  def license_valid
    # Don't validate license on edits
    return unless id.nil?

    if license.nil?
      errors.add(:license, 'must be chosen')
      return
    end

    unless license.enabled?
      errors.add(:license, 'is not available for use')
    end
  end

  def maximum_tags
    if tags_cache.length > 5
      errors.add(:tags, "can't have more than 5 tags")
    elsif tags_cache.empty?
      errors.add(:tags, 'must have at least one tag')
    end
  end

  def maximum_tag_length
    tags_cache.each do |tag|
      max_len = SiteSetting['MaxTagLength']
      if tag.length > max_len
        errors.add(:tags, "can't be more than #{max_len} characters long each")
      end
    end
  end

  def no_spaces_in_tags
    tags_cache.each do |tag|
      if tag.include?(' ') || tag.include?('_')
        errors.add(:tags, 'may not include spaces or underscores - use hyphens for multiple-word tags')
      end
    end
  end

  def stripped_minimum
    if (body&.gsub(/(?:^[\s\t\u2000-\u200F]+|[\s\t\u2000-\u200F]+$)/, '')&.length || 0) < 30
      errors.add(:body, 'must be more than 30 non-whitespace characters long')
    end
    if (title&.gsub(/(?:^[\s\t\u2000-\u200F]+|[\s\t\u2000-\u200F]+$)/, '')&.length || 0) < 15
      errors.add(:title, 'must be more than 15 non-whitespace characters long')
    end
  end

  def tags_in_tag_set
    tag_set = category.tag_set
    unless tags.all? { |t| t.tag_set_id == tag_set.id }
      errors.add(:base, "Not all of this question's tags are in the correct tag set.")
    end
  end

  def required_tags?
    required = category&.required_tag_ids
    return unless required.present? && !required.empty?

    unless tag_ids.any? { |t| required.include? t }
      errors.add(:tags, "must contain at least one required tag (#{category.required_tags.pluck(:name).join(', ')})")
    end
  end

  def moderator_tags
    mod_tags = category&.moderator_tags&.map(&:name)
    return unless mod_tags.present? && !mod_tags.empty?
    return if RequestContext.user&.is_moderator

    sc = changes
    return unless sc.include? 'tags_cache'

    if (sc['tags_cache'][0] || []) & mod_tags != (sc['tags_cache'][1] || []) & mod_tags
      errors.add(:base, "You don't have permission to change moderator-only tags.")
    end
  end

  def update_category_activity
    if saved_changes.include? 'last_activity'
      category.update_activity(last_activity)
    end
  end
end
