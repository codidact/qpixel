class Post < ApplicationRecord
  belongs_to :user
  belongs_to :post_type
  belongs_to :parent, class_name: 'Post', required: false, counter_cache: :answer_count
  belongs_to :closed_by, class_name: 'User', required: false
  belongs_to :deleted_by, class_name: 'User', required: false
  has_and_belongs_to_many :tags, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :post_histories, dependent: :destroy
  has_many :flags, dependent: :destroy
  has_many :children, class_name: 'Post', foreign_key: 'parent_id', dependent: :destroy

  serialize :tags_cache, Array

  validates :body, presence: true, length: {minimum: 30, maximum: 30000}

  scope :undeleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }

  after_save :check_attribution_notice
  after_save :modify_author_reputation
  after_save :reset_last_activity
  after_create :create_initial_revision

  def self.search(term)
    match_search term, posts: :body_markdown
  end

  def reassign_user(new_user)
    # Three updates: one to remove rep from previous user, one to reassign, one to re-grant rep to new user
    update(deleted: true, deleted_at: DateTime.now, deleted_by: User.find(-1))
    update(user: new_user)
    votes.update_all(recv_user_id: new_user.id)
    update(deleted: false, deleted_at: nil, deleted_by: nil)
  end

  private

  def attribution_text(source=nil, name=nil, url=nil)
    "Source: #{source || att_source}\nLicense name: #{name || att_license_name}\nLicense URL: #{url || att_license_link}"
  end

  def check_attribution_notice
    sc = saved_changes
    attributes = ['att_source', 'att_license_name', 'att_license_link']
    if attributes.any? { |x| sc.include?(x) && sc[x][0] != sc[x][1] }
      if attributes.all? { |x| sc[x]&.try(:[], 0).nil? }
        PostHistory.attribution_notice_added(self, User.find(-1), nil, attribution_text)
      elsif attributes.all? { |x| sc[x]&.try(:[], 1).nil? }
        PostHistory.attribution_notice_removed(self, User.find(-1), attribution_text(*attributes.map { |a| sc[a]&.try(:[], 0) }), nil)
      else
        PostHistory.attribution_notice_changed(self, User.find(-1), attribution_text(*attributes.map { |a| sc[a]&.try(:[], 0) }),
                                               attribution_text(*attributes.map { |a| sc[a]&.try(:[], 1) }))
      end
    end
  end

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

  def reset_last_activity
    ap "reset_last_activity"
    ap saved_changes
    exempt_attributes = ['updated_at', 'score', 'att_source', 'att_license_link', 'att_license_name']
    ap saved_changes.keys.all? { |k| exempt_attributes.include? k }
    unless saved_changes.keys.all? { |k| exempt_attributes.include? k }
      if last_activity && last_activity <= 60.seconds.ago
        update(last_activity: DateTime.now)
        if parent.present?
          parent.update(last_activity: DateTime.now)
        end
      end
    end
  end

  def create_initial_revision
    PostHistory.initial_revision(self, user, nil, body_markdown)
  end
end