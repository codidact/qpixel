# Represents a vote. A vote is attached to both a 'post' (i.e. a question or an answer - this is a polymorphic
# association), and to a user.
class Vote < ApplicationRecord
  include PostRelated
  belongs_to :user, optional: false
  belongs_to :recv_user, class_name: 'User', optional: false

  after_create :apply_rep_change
  after_create :add_counter
  before_destroy :check_valid
  before_destroy :reverse_rep_change

  after_destroy :remove_counter

  validates :vote_type, inclusion: [1, -1]
  validate :post_not_deleted

  def self.total_rep_change(col)
    col = col.includes(:post, post: [:category, :post_type])

    col.reduce(0) do |sum, vote|
      sum + (CategoryPostType.rep_changes[[vote.post.category_id, vote.post.post_type_id]][vote.vote_type] || 0)
    end
  end

  private

  def apply_rep_change
    rep_change(+1)
  end

  def reverse_rep_change
    rep_change(-1)
  end

  def rep_change(direction)
    change = CategoryPostType.rep_changes[[post.category_id, post.post_type_id]][vote_type] || 0
    recv_user.update!(reputation: recv_user.reputation + direction * change)
  end

  def post_not_deleted
    if post.deleted?
      errors.add(:base, 'Votes are locked on deleted posts')
    end
  end

  def check_valid
    throw :abort unless valid?
  end

  def add_counter
    case vote_type
    when 1
      post.update(upvote_count: post.upvote_count + 1)
    when -1
      post.update(downvote_count: post.downvote_count + 1)
    end
    post.recalc_score
  end

  def remove_counter
    case vote_type
    when 1
      post.update(upvote_count: [post.upvote_count - 1, 0].max)
    when -1
      post.update(downvote_count: [post.downvote_count - 1, 0].max)
    end
    post.recalc_score
  end
end
