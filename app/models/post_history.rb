class PostHistory < ApplicationRecord
  include PostRelated
  belongs_to :post_history_type
  belongs_to :user
  has_many :post_history_tags, dependent: :destroy
  has_many :tags, through: :post_history_tags

  belongs_to :close_reason, optional: true
  belongs_to :duplicate_post, class_name: 'Post', optional: true

  def before_tags
    tags.where(post_history_tags: { relationship: 'before' })
  end

  def after_tags
    tags.where(post_history_tags: { relationship: 'after' })
  end

  # @return [Array] the tags that were removed in this history step
  def tags_removed
    before_tags - after_tags
  end

  # @return [Array] the tags that were added in this history step
  def tags_added
    after_tags - before_tags
  end

  def reverted?
    !reverted_with_id.nil?
  end

  # @param user [User]
  # @return [Boolean] whether the given user is allowed to see the details of this history item
  def allowed_to_see_details?(user)
    !hidden || user&.is_admin || user_id == user&.id || post.user_id == user&.id
  end

  def self.method_missing(name, *args, **opts)
    unless args.length >= 2
      raise NoMethodError
    end

    object, user = args
    fields = [:before, :after, :comment, :before_title, :after_title, :before_tags, :after_tags, :close_reason_id,
              :duplicate_post_id, :hidden]
    values = fields.to_h { |f| [f, nil] }.merge(opts)

    history_type_name = name.to_s
    history_type = PostHistoryType.find_by(name: history_type_name)
    if history_type.nil?
      super
      return
    end

    params = { post_history_type: history_type, user: user, post: object, community_id: object.community_id }
    { before: :before_state, after: :after_state, comment: :comment, before_title: :before_title,
      after_title: :after_title, close_reason_id: :close_reason_id, duplicate_post_id: :duplicate_post_id,
      hidden: :hidden }.each do |arg, attr|
      next if values[arg].nil?

      params = params.merge(attr => values[arg])
    end

    history = PostHistory.create params

    post_history_tags = { before_tags: 'before', after_tags: 'after' }.to_h do |arg, rel|
      if values[arg].nil?
        [arg, nil]
      else
        [arg, values[arg].map { |t| { post_history_id: history.id, tag_id: t.id, relationship: rel } }]
      end
    end.values.compact.flatten

    history.post_history_tags = PostHistoryTag.create(post_history_tags)

    history
  end

  def self.respond_to_missing?(method_name, include_private = false)
    PostHistoryType.exists?(name: method_name.to_s) || super
  end

  # @return [Boolean] whether this history item can be rolled back
  def can_rollback?
    return false if reverted? || hidden

    case post_history_type.name
    when 'post_deleted'
      post.deleted?
    when 'post_undeleted'
      !post.deleted?
    when 'question_closed'
      post.closed?
    when 'question_reopened'
      !post.closed?
    when 'post_edited'
      # Post title must be still what it was after the edit
      (after_title.nil? || after_title == before_title || after_title == post.title) &&
        # Post body must be still the same
        (after_state.nil? || after_state == before_state || after_state == post.body_markdown) &&
        # Post tags that were removed must not have been re-added
        (tags_removed & post.tags == []) &&
        # Post tags that were added must not have been removed
        (tags_added - post.tags == [])
    when 'history_hidden', 'history_revealed'
      true
    else
      false
    end
  end

  # Attempts to find a predecessor event (event that came before) of the given type.
  # This method will return the predecessor with the greatest created_at timestamp.
  #
  # @param type [PostHistoryType, String]
  # @return [PostHistoryType, Nil] the predecessor of this event of the given type, if any exists
  def find_predecessor(type)
    type = if type.is_a?(PostHistoryType)
             type
           else
             PostHistoryType.find_by(name: type)
           end

    post.post_histories
        .where(post_history_type: type)
        .where(created_at: ..created_at)
        .where.not(id: id)
        .order(created_at: :desc, id: :desc)
        .first
  end
end
