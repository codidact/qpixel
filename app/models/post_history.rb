class PostHistory < ApplicationRecord
  include PostRelated
  belongs_to :post_history_type
  belongs_to :user
  has_many :post_history_tags
  has_many :tags, through: :post_history_tags

  # Limits the history (across multiple posts) which should be visible for the given user.
  # @param user [User, Nil]
  scope :visible, lambda { |user|
    unless user&.is_admin
      # This collects for each post the last time that the post was redacted.
      subquery = where(post_history_type_id: PostHistoryType.find_by(name: 'post_redacted').id)
                 .group(:post_id)
                 .select(Arel.sql('post_id, IFNULL(MAX(post_histories.created_at), 0) target_created_at'))

      # Do include history where the current user is the redactor or the poster
      unless user.nil?
        subquery = subquery.where.not(user: user)
                           .joins(:post)
                           .where.not(posts: { user: user })
      end

      # Show only history after the last redaction for each post
      joins(Arel.sql("LEFT OUTER JOIN (#{subquery.to_sql}) sub ON post_histories.post_id = sub.post_id"))
        .where.not(post_history_type_id: PostHistoryType.find_by(name: 'post_redacted').id)
        .where(arel_table[:created_at].gteq(Arel.sql('sub.target_created_at'))
                                      .or(Arel.sql('sub.target_created_at IS NULL')))
    end
  }

  def before_tags
    tags.where(post_history_tags: { relationship: 'before' })
  end

  def after_tags
    tags.where(post_history_tags: { relationship: 'after' })
  end

  def self.method_missing(name, *args, **opts)
    unless args.length >= 2
      raise NoMethodError
    end

    object, user = args
    fields = [:before, :after, :comment, :before_title, :after_title, :before_tags, :after_tags]
    values = fields.to_h { |f| [f, nil] }.merge(opts)

    history_type_name = name.to_s
    history_type = PostHistoryType.find_by(name: history_type_name)
    if history_type.nil?
      super
      return
    end

    params = { post_history_type: history_type, user: user, post: object, community_id: object.community_id }
    { before: :before_state, after: :after_state, comment: :comment, before_title: :before_title,
      after_title: :after_title }.each do |arg, attr|
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
end
