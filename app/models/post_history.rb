class PostHistory < ActiveRecord::Base
  has_one :post_history_type
  has_one :user
  belongs_to :post, :polymorphic => true

  def self.question_edited(question, user=nil)
    self.new_question_event('Edit', question, user)
  end

  def self.question_deleted(question, user=nil)
    self.new_question_event('Delete', question, user)
  end

  def self.question_undeleted(question, user=nil)
    self.new_question_event('Undelete', question, user)
  end

  def self.answer_edited(answer, user=nil)
    self.new_answer_event('Edit', answer, user)
  end

  def self.answer_deleted(answer, user=nil)
    self.new_answer_event('Delete', answer, user)
  end

  def self.answer_undeleted(answer, user=nil)
    self.new_answer_event('Undelete', answer, user)
  end

  private
    def self.new_question_event(type_name, question, user=nil)
      event = PostHistory.new
      event.post_history_type = PostHistoryType.find_by_name type_name
      event.user = user || (current_user if user_signed_in?)
      event.post = question
      event.save!
    end

    def self.new_answer_event(type_name, answer, user=nil)
      event = PostHistory.new
      event.post_history_type = PostHistoryType.find_by_name type_name
      event.user = user || (current_user if user_signed_in?)
      event.post = answer
      event.save!
    end
end
