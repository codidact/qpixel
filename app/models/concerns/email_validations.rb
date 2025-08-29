module EmailValidations
  extend ActiveSupport::Concern

  included do
    validate :email_domain_not_blocklisted
    validate :email_not_blocklisted
    validate :email_not_bad_pattern
  end

  class_methods do
    def bad_email_patterns_path
      Rails.root.join('../.qpixel-email-patterns.txt')
    end

    def blocklisted_email_domains_path
      Rails.root.join('../.qpixel-domain-blocklist.txt')
    end

    # Gets a list of blocklisted email domains
    # @returns [Array<String>] list of domains
    def blocklisted_email_domains
      return [] unless File.exist?(blocklisted_email_domains_path)

      File.read(blocklisted_email_domains_path).split("\n")
    end

    # Gets a list of bad email patterns
    # @return [Array<String>] list of patterns
    def bad_email_patterns
      return [] unless File.exist?(bad_email_patterns_path)

      File.read(bad_email_patterns_path).split("\n")
    end
  end

  def email_domain_not_blocklisted
    return unless saved_changes.include?('email')

    email_domain = email.split('@')[-1]
    matched = self.class.blocklisted_email_domains.select { |x| email_domain == x }
    if matched.any?
      errors.add(:base, ApplicationRecord.useful_err_msg.sample)
      matched_domains = matched.map { |d| "equals: #{d}" }
      AuditLog.block_log(event_type: 'user_email_domain_blocked',
                         comment: "email: #{email}\n#{matched_domains.join("\n")}\nsource: file")
    end
  end

  def email_not_blocklisted
    return unless saved_changes.include?('email')

    email_domain = email.split('@')[-1]
    is_mail_blocked = BlockedItem.emails.where(value: email)
    is_mail_host_blocked = BlockedItem.email_hosts.where(value: email_domain)
    if is_mail_blocked.any? || is_mail_host_blocked.any?
      errors.add(:base, ApplicationRecord.useful_err_msg.sample)
      if is_mail_blocked.any?
        AuditLog.block_log(event_type: 'user_email_blocked', related: is_mail_blocked.first,
                           comment: "email: #{email}\nfull match to: #{is_mail_blocked.first.value}")
      end
      if is_mail_host_blocked.any?
        AuditLog.block_log(event_type: 'user_email_domain_blocked', related: is_mail_host_blocked.first,
                           comment: "email: #{email}\ndomain match to: #{is_mail_host_blocked.first.value}")
      end
    end
  end

  def email_not_bad_pattern
    return unless changes.include?('email')

    matched = self.class.bad_email_patterns.select { |p| email.match? Regexp.new(p) }
    if matched.any?
      errors.add(:base, ApplicationRecord.useful_err_msg.sample)
      matched_patterns = matched.map { |p| "matched: #{p}" }
      AuditLog.block_log(event_type: 'user_email_pattern_match',
                         comment: "email: #{email}\n#{matched_patterns.join("\n")}")
    end
  end
end
