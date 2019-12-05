class Post < ApplicationRecord
  belongs_to :user
  belongs_to :post_type
  belongs_to :parent, class_name: 'Post', required: false, counter_cache: :answer_count
  belongs_to :closed_by, class_name: 'User', required: false
  belongs_to :deleted_by, class_name: 'User', required: false
  has_and_belongs_to_many :tags
  has_many :votes
  has_many :comments
  has_many :post_histories
  has_many :flags

  serialize :tags_cache, Array

  validates :body, presence: true, length: {minimum: 30, maximum: 30000}

  scope :undeleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }

  after_save :check_attribution_notice
  after_save :modify_author_reputation
  after_save :reset_last_activity

  private

  def attribution_text(source=nil, name=nil, url=nil)
    "Source: #{source || att_source}\nLicense name: #{name || att_license_name}\nLicense URL: #{url || att_license_link}"
  end

  def check_attribution_notice
    sc = saved_changes
    attributes = ['att_source', 'att_license_name', 'att_license_link']
    if attributes.any? { |x| sc.include?(x) && sc[x][0] != sc[x][1] }
      if attributes.all? { |x| sc[x][0].nil? }
        PostHistory.attribution_notice_added(self, User.find(-1), nil, attribution_text)
      elsif attributes.all? { |x| sc[x][1].nil? }
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
    if last_activity && last_activity <= 60.seconds.ago
      update(last_activity: DateTime.now)
      if parent.present?
        parent.update(last_activity: DateTime.now)
      end
    end
  end
end