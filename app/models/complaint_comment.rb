class ComplaintComment < ApplicationRecord
  belongs_to :complaint
  belongs_to :user, required: false

  validates :content, presence: true
  validate :can_add_more, on: :create

  scope :internal, -> { where(internal: true) }
  scope :external, -> { where(internal: false) }
  scope :most_recent, -> { order(created_at: :desc).limit(1).first }

  private

  def can_add_more
    if complaint.status == 'closed' && user_id != -1 && !user.staff?
      errors.add(:base, 'You cannot reply to a closed complaint') and return
    end

    unless user_id == -1 || internal? || complaint.can_add_more_comments?(user)
      errors.add(:base, 'You can only add one reply between staff responses')
    end
  end
end
