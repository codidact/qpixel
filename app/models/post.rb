class Post < ApplicationRecord
  belongs_to :user
  belongs_to :post_type
  belongs_to :parent, class_name: 'Post', required: false
  belongs_to :closed_by, class_name: 'User', required: false
  belongs_to :deleted_by, class_name: 'User', required: false
  has_many :votes
  has_many :comments
  has_many :post_histories
  has_many :flags

  serialize :tags, Array

  validates :body, presence: true, length: { minimum: 30, maximum: 30000 }

  scope :undeleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }

  after_save :modify_author_reputation

  private

  def modify_author_reputation
    sc = saved_changes
    if sc.include?('deleted') && sc['deleted'][0] != sc['deleted'][1] && created_at >= 60.days.ago
      deleted = !!saved_changes['deleted']&.last
      if deleted
        user.update(reputation: user.reputation - Vote.total_rep_change(votes))
      else
        user.update(reputation: user.reputation + Vote.total_rep_change(votes))
      end
    end
  end
end