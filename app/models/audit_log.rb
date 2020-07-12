class AuditLog < ApplicationRecord
  include CommunityRelated

  belongs_to :related, polymorphic: true, required: false
  belongs_to :user, required: false

  class << self
    [:admin_audit, :moderator_audit, :action_audit, :user_annotation, :user_history].each do |log_type|
      define_method(log_type) do |**values|
        create(values.merge(log_type: log_type.to_s, community_id: RequestContext.community_id))
      end
    end
  end
end
