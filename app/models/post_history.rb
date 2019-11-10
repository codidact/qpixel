class PostHistory < ActiveRecord::Base
  belongs_to :post_history_type
  belongs_to :user
  belongs_to :post

  def self.question_edited(question, user)
    self.new_question_event('Edit', question, user)
  end

  def self.question_deleted(question, user)
    self.new_question_event('Delete', question, user)
  end

  def self.question_undeleted(question, user)
    self.new_question_event('Undelete', question, user)
  end

  def self.question_closed(question, user)
    self.new_question_event('Close', question, user)
  end

  def self.question_reopened(question, user)
    self.new_question_event('Reopen', question, user)
  end

  def self.answer_edited(answer, user)
    self.new_answer_event('Edit', answer, user)
  end

  def self.answer_deleted(answer, user)
    self.new_answer_event('Delete', answer, user)
  end

  def self.answer_undeleted(answer, user)
    self.new_answer_event('Undelete', answer, user)
  end

  private
    def self.new_question_event(type_name, question, user)
      event = PostHistory.new
      event.post_history_type = PostHistoryType.find_by_name type_name
      event.user = user
      event.post = question
      event.save!
    end

    def self.new_answer_event(type_name, answer, user)
      event = PostHistory.new
      event.post_history_type = PostHistoryType.find_by_name type_name
      event.user = user
      event.post = answer
      event.save!
    end
end
