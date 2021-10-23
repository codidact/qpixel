class AuditLog < ApplicationRecord
  include CommunityRelated

  belongs_to :related, polymorphic: true, optional: true
  belongs_to :user, optional: true

  class << self
    [:admin_audit, :moderator_audit, :action_audit, :user_annotation, :user_history, :pii_history, :block_log,
     :rate_limit_log].each do |log_type|
      define_method(log_type) do |**values|
        create(values.merge(log_type: log_type.to_s, community_id: RequestContext.community_id))
      end
    end
  end
end
