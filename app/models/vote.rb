# Represents a vote. A vote is attached to both a 'post' (i.e. a question or an answer - this is a polymorphic
# association), and to a user.
class Vote < ApplicationRecord
  include PostRelated
  belongs_to :user, required: true
  belongs_to :recv_user, class_name: 'User', required: true

  after_create :apply_rep_change
  before_destroy :check_valid
  before_destroy :reverse_rep_change

  after_create :add_counter
  after_destroy :remove_counter

  validates :vote_type, inclusion: [1, -1]
  validate :post_not_deleted

  def self.total_rep_change(col)
    col = col.includes(:post)
    settings = SiteSetting.where(name: ['QuestionUpVoteRep', 'QuestionDownVoteRep',
                                        'AnswerUpVoteRep', 'AnswerDownVoteRep',
                                        'ArticleUpVoteRep', 'ArticleDownVoteRep'])
                          .map { |ss| [ss.name, ss.value] }.to_h
    rep_changes = PostType.mapping.map do |k, v|
      vote_types = { 1 => 'Up', -1 => 'Down' }
      [v, vote_types.transform_values { |readable| settings["#{k}#{readable}VoteRep"].to_i }]
    end.to_h

    col.reduce(0) { |sum, vote| sum + rep_changes[vote.post.post_type_id][vote.vote_type] }
  end

  private

  def apply_rep_change
    rep_change(+1)
  end

  def reverse_rep_change
    rep_change(-1)
  end

  def rep_change(direction)
    post_type_ids = Rails.cache.fetch :post_type_ids do
      PostType.mapping
    end
    setting_names = {
      [post_type_ids['Question'], 1] => 'QuestionUpVoteRep',
      [post_type_ids['Question'], -1] => 'QuestionDownVoteRep',
      [post_type_ids['Answer'], 1] => 'AnswerUpVoteRep',
      [post_type_ids['Answer'], -1] => 'AnswerDownVoteRep',
      [post_type_ids['Article'], 1] => 'ArticleUpVoteRep',
      [post_type_ids['Article'], -1] => 'ArticleDownVoteRep'
    }
    rep_change = SiteSetting[setting_names[[post.post_type_id, vote_type]]] || 0
    recv_user.update!(reputation: recv_user.reputation + direction * rep_change)
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
    if vote_type == 1
      post.update(upvote_count: post.upvote_count + 1)
    elsif vote_type == -1
      post.update(downvote_count: post.downvote_count + 1)
    end
    post.recalc_score
  end

  def remove_counter
    if vote_type == 1
      post.update(upvote_count: [post.upvote_count - 1, 0].max)
    elsif vote_type == -1
      post.update(downvote_count: [post.downvote_count - 1, 0].max)
    end
    post.recalc_score
  end
end
