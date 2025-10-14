class ComplaintComment < ApplicationRecord
  belongs_to :complaint
  belongs_to :user, required: false

  validates :content, presence: true
  validate :can_add_more, on: :create

  scope :internal, -> { where(internal: true) }
  scope :external, -> { where(internal: false) }

  private

  def can_add_more
    unless complaint.can_add_more_comments?(user)
      errors.add(:base, 'You can only add one reply between staff responses')
    end
  end
end
