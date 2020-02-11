# Represents a vote. A vote is attached to both a 'post' (i.e. a question or an answer - this is a polymorphic
# association), and to a user.
class Vote < ApplicationRecord
  include PostRelated
  belongs_to :user, required: true
  belongs_to :recv_user, class_name: 'User', required: true

  after_create :apply_rep_change
  after_create :change_post_score
  before_destroy :reverse_rep_change
  before_destroy :restore_post_score

  validates :vote_type, inclusion: [1, -1]

  def self.total_rep_change(col)
    col = col.includes(:post)
    settings = SiteSetting.where(name: ['QuestionUpVoteRep', 'QuestionDownVoteRep', 'AnswerUpVoteRep', 'AnswerDownVoteRep'])
                   .map { |ss| [ss.name, ss.value] }.to_h
    rep_changes = PostType.mapping.map do |k, v|
      vote_types = {1 => 'Up', -1 => 'Down'}
      [v, vote_types.map { |vt, readable| [vt, settings["#{k}#{readable}VoteRep"].to_i] }.to_h]
    end.to_h

    col.reduce(0) { |sum, vote| sum + rep_changes[vote.post.post_type_id][vote.vote_type] }
  end

  private

  def apply_rep_change
    rep_change +1
  end

  def reverse_rep_change
    rep_change -1
  end

  def rep_change(direction)
    post_type_ids = Rails.cache.fetch :post_type_ids do
      PostType.mapping
    end
    setting_names = {
        [post_type_ids['Question'], 1] => 'QuestionUpVoteRep',
        [post_type_ids['Question'], -1] => 'QuestionDownVoteRep',
        [post_type_ids['Answer'], 1] => 'AnswerUpVoteRep',
        [post_type_ids['Answer'], -1] => 'AnswerDownVoteRep'
    }
    rep_change = SiteSetting[setting_names[[post.post_type_id, vote_type]]] || 0
    recv_user.update!(reputation: recv_user.reputation + direction * rep_change)
  end

  def change_post_score
    post.update!(score: post.score + vote_type)
  end

  def restore_post_score
    post.update!(score: post.score - vote_type)
  end
end
