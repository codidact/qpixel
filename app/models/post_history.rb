class PostHistory < ApplicationRecord
  include PostRelated
  include EditsValidations

  belongs_to :post_history_type
  belongs_to :user
  has_many :post_history_tags
  has_many :tags, through: :post_history_tags

  def before_tags
    tags.where(post_history_tags: { relationship: 'before' })
  end

  def after_tags
    tags.where(post_history_tags: { relationship: 'after' })
  end

  # Checks whether a given user is allowed to see post history item deltails
  # @param user [User] user to check for
  # @return [Boolean] check result
  def allowed_to_see_details?(user)
    !hidden || user&.admin? || user_id == user&.id || post.user_id == user&.id
  end

  # Hides all previous history
  # @param post [Post] post to redact history for
  # @param user [User] user that is redacting the history
  def self.redact(post, user)
    where(post: post).update_all(hidden: true)
    history_hidden(post, user, after: post.body_markdown,
                                    after_title: post.title,
                                    after_tags: post.tags,
                                    comment: 'Detailed history before this event is hidden because of a redaction.')
  end

  def self.method_missing(name, *args, **opts)
    unless args.length >= 2
      raise NoMethodError
    end

    object, user = args
    fields = [:before, :after, :comment, :before_title, :after_title, :before_tags, :after_tags, :hidden]
    values = fields.to_h { |f| [f, nil] }.merge(opts)

    history_type_name = name.to_s
    history_type = PostHistoryType.find_by(name: history_type_name)
    if history_type.nil?
      super
      return
    end

    params = { post_history_type: history_type, user: user, post: object, community_id: object.community_id }
    { before: :before_state, after: :after_state, comment: :comment, before_title: :before_title,
      after_title: :after_title, hidden: :hidden }.each do |arg, attr|
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

    # do not create post history tags if post history validations failed
    unless history.errors.any?
      history.post_history_tags = PostHistoryTag.create(post_history_tags)
    end

    history
  end

  def self.respond_to_missing?(method_name, include_private = false)
    PostHistoryType.exists?(name: method_name.to_s) || super
  end
end
