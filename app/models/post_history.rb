class PostHistory < ActiveRecord::Base
  has_one :post_history_type
  has_one :user
  belongs_to :post, :polymorphic => true

  def self.new_from_question(question, type_name, user=nil)
    event = PostHistory.new
    event.body = question.body
    event.title = question.title
    event.tags = question.tags
    event.post_history_type = PostHistoryType.find_by_name type_name
    event.user = user || (current_user if user_signed_in?)
    event.save!
  end
end
