# Validations for post histories
module PostHistoryValidations
  extend ActiveSupport::Concern

  included do
    validate :max_edit_comment_length
  end

  def max_edit_comment_length
    max_edit_comment_length = SiteSetting['MaxEditCommentLength']
    max_length = [(max_edit_comment_length || 255), 255].min
    if comment.length > max_length
      msg = I18n.t('post_histories.max_edit_comment_length').gsub(':length', max_length.to_s)
      errors.add(:base, msg)
    end
  end
end
