# Validations for post histories
module PostHistoryValidations
  extend ActiveSupport::Concern

  included do
    validate :max_edit_comment_length
  end

  def max_edit_comment_length
    max_edit_comment_length = SiteSetting['MaxEditCommentLength']
    if comment.length > [(max_edit_comment_length || 255), 255].min
      errors.add(:comment, "can't be more than #{max_edit_comment_length} characters")
    end
  end
end