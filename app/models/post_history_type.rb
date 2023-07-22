class PostHistoryType < ApplicationRecord
  INVERSES = {
    'post_deleted' => 'post_undeleted',
    'post_undeleted' => 'post_deleted',
    'question_closed' => 'question_reopened',
    'question_reopened' => 'question_closed',
    'attribution_notice_added' => 'attribution_notice_removed',
    'attribution_notice_removed' => 'attribution_notice_added',
    'nominated_for_promotion' => 'promotion_removed',
    'promotion_removed' => 'nominated_for_promotion'
  }.freeze

  has_many :post_histories

  validates :name, uniqueness: { case_sensitive: false }

  # @return [String] the name of the opposite post history type. If there is no opposite, the name is returned unchanged
  def name_inverted
    INVERSES.fetch(name, name)
  end
end
