class Post < ApplicationRecord
  require 'redcarpet/render_strip'

  include CommunityRelated

  belongs_to :user
  belongs_to :post_type
  belongs_to :parent, class_name: 'Post', required: false, counter_cache: :answer_count
  belongs_to :closed_by, class_name: 'User', required: false
  belongs_to :deleted_by, class_name: 'User', required: false
  belongs_to :last_activity_by, class_name: 'User', required: false
  belongs_to :category, required: false
  belongs_to :license, required: false
  has_and_belongs_to_many :tags, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :post_histories, dependent: :destroy
  has_many :flags, dependent: :destroy
  has_many :children, class_name: 'Post', foreign_key: 'parent_id', dependent: :destroy

  serialize :tags_cache, Array

  validates :body, presence: true, length: { minimum: 30, maximum: 30_000 }
  validates :doc_slug, uniqueness: { scope: [:community_id] }, if: -> { doc_slug.present? }
  validates :title, :body, :tags_cache, presence: true, if: :question?
  validate :tags_in_tag_set, if: :question?
  validate :maximum_tags, if: :question?
  validate :maximum_tag_length, if: :question?
  validate :no_spaces_in_tags, if: :question?
  validate :stripped_minimum, if: :question?
  validate :category_allows_post_type
  validate :license_available
  validate :required_tags?

  scope :undeleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }
  scope :qa_only, -> { where(post_type_id: [Question.post_type_id, Answer.post_type_id]) }
  scope :list_includes, -> { includes(:user, :tags, user: :avatar_attachment) }

  after_save :check_attribution_notice
  after_save :modify_author_reputation
  after_save :copy_last_activity_to_parent
  after_save :break_description_cache
  before_validation :update_tag_associations, if: :question?
  after_create :create_initial_revision
  after_create :add_license_if_nil

  def self.search(term)
    match_search term, posts: :body_markdown
  end

  # Double-define: initial definitions are less efficient, so if we have a record of the post type we'll
  # override them later with more efficient methods.
  ['Question', 'Answer', 'PolicyDoc', 'HelpDoc'].each do |pt|
    define_method "#{pt.underscore}?" do
      post_type_id == pt.constantize.post_type_id
    end
  end

  PostType.all.each do |pt|
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
    PostsController.renderer.render(body_markdown)
  end

  def question?
    post_type_id == Question.post_type_id
  end

  def answer?
    post_type_id == Answer.post_type_id
  end

  def pending_suggested_edit?
    SuggestedEdit.where(post_id: id, active: true).any?
  end

  def pending_suggested_edit
    SuggestedEdit.where(post_id: id, active: true).take
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
    if parent.present? && (sc.include?('last_activity') || sc.include?('last_activity_by_id'))
      unless parent.update(last_activity: last_activity, last_activity_by: last_activity_by)
        Rails.logger.error "Parent failed copy_last_activity update (#{parent.errors.full_messages.join(';')})"
      end
    end
  end

  def modify_author_reputation
    sc = saved_changes
    if sc.include?('deleted') && sc['deleted'][0] != sc['deleted'][1] && created_at >= 60.days.ago
      deleted = !!saved_changes['deleted']&.last # rubocop:disable Style/DoubleNegation
      if deleted
        user.update(reputation: user.reputation - Vote.total_rep_change(votes))
      else
        user.update(reputation: user.reputation + Vote.total_rep_change(votes))
      end
    end
  end

  def create_initial_revision
    PostHistory.initial_revision(self, user, after: body_markdown)
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

  def license_available
    # Don't validate license on edits
    return unless id.nil?

    unless license.nil? || license.enabled?
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
      if tag.include? ' '
        errors.add(:tags, 'may not include spaces - use hyphens for multiple-word tags')
      end
    end
  end

  def stripped_minimum
    if (body&.squeeze('  ')&.length || 0) < 30
      errors.add(:body, 'must be more than 30 non-whitespace characters long')
    end
    if (title&.squeeze('  ')&.length || 0) < 15
      errors.add(:title, 'must be more than 15 non-whitespace characters long')
    end
  end

  def tags_in_tag_set
    tag_set = category.tag_set
    unless tags.all? { |t| t.tag_set_id == tag_set.id }
      errors.add(:base, "Not all of this question's tags are in the correct tag set.")
    end
  end

  def add_license_if_nil
    if license.nil?
      update(license: License.site_default)
    end
  end

  def required_tags?
    required = category&.required_tag_ids
    return unless required.present? && !required.empty?

    unless tag_ids.any? { |t| required.include? t }
      errors.add(:tags, "must contain at least one required tag (#{category.required_tags.pluck(:name).join(', ')})")
    end
  end
end
