class PostHistory < ApplicationRecord
  belongs_to :post_history_type
  belongs_to :user
  belongs_to :post

  def self.method_missing(name, *args, &block)
    unless args.length >= 2
      raise NoMethodError.new
    end
    object, user, before_state, after_state = args
    history_type_name = name.to_s
    history_type = PostHistoryType.find_by(name: history_type_name)
    raise NoMethodError.new if history_type.nil?

    params = { post_history_type: history_type, user: user, post: object }
    unless before_state.nil?
      params = params.merge(before_state: before_state)
    end
    unless after_state.nil?
      params = params.merge(after_state: after_state)
    end

    PostHistory.create params
  end
end
