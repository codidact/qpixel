class PostHistoryType < ApplicationRecord
  INVERSES = {
    'post_deleted' => 'post_undeleted',
    'post_undeleted' => 'post_deleted',
    'question_closed' => 'question_reopened',
    'question_reopened' => 'question_closed',
    'attribution_notice_added' => 'attribution_notice_removed',
    'attribution_notice_removed' => 'attribution_notice_added',
    'nominated_for_promotion' => 'promotion_removed',
    'promotion_removed' => 'nominated_for_promotion',
    'history_hidden' => 'history_revealed',
    'history_revealed' => 'history_hidden'
  }.freeze
  REVERT_TO_TYPES = %w[
    post_edited
    initial_revision
    imported_from_external_source
  ].freeze

  has_many :post_histories

  validates :name, uniqueness: { case_sensitive: false }

  # @return [Boolean] whether one can roll back to an event of this type.
  def can_be_rolled_back_to?
    REVERT_TO_TYPES.include?(name)
  end

  # @return [Boolean] whether this event relates to hiding/revealing of history
  def history_hiding_related?
    %w[history_hidden history_revealed].include?(name)
  end

  # @return [String] the name of the opposite post history type. If there is no opposite, the name is returned unchanged
  def name_inverted
    INVERSES.fetch(name, name)
  end
end
