class PostHistory < ApplicationRecord
  belongs_to :post_history_type
  belongs_to :user
  belongs_to :post

  validates :name, uniqueness: true

  def self.method_missing(name, *args, &block)
    unless args.length >= 2
      raise NoMethodError.new
    end
    object = args[0]
    user = args[1]
    history_type_name = name.to_s
    history_type = PostHistoryType.find_by(name: history_type_name)
    raise NoMethodError.new if history_type.nil?
    PostHistory.create(post_history_type: history_type, user: user, post: object)
  end
end
