class PostHistory < ApplicationRecord
  belongs_to :post_history_type
  belongs_to :user
  belongs_to :post

  def self.method_missing(name, *args, **opts, &block)
    unless args.length >= 2
      raise NoMethodError.new
    end
    object, user = args
    before, after, comment = { before: nil, after: nil, comment: nil }.merge(opts).values_at(:before, :after, :comment)

    history_type_name = name.to_s
    history_type = PostHistoryType.find_by(name: history_type_name)
    raise NoMethodError.new if history_type.nil?

    params = { post_history_type: history_type, user: user, post: object }
    unless before.nil?
      params = params.merge(before_state: before)
    end
    unless after.nil?
      params = params.merge(after_state: after)
    end
    unless comment.nil?
      params = params.merge(comment: comment)
    end

    PostHistory.create params
  end
end
