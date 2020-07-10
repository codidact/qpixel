class AuditLog < ApplicationRecord
  belongs_to :related, polymorphic: true
  belongs_to :user

  def self.admin_audit(**values)
    create(values.merge(log_type: 'admin_audit'))
  end

  def self.moderator_audit(**values)
    create(values.merge(log_type: 'moderator_audit'))
  end

  def self.user_annotation(**values)
    create(values.merge(log_type: 'user_annotation'))
  end
end
