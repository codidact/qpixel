module UsernameValidations
  extend ActiveSupport::Concern

  included do
    validates :username, presence: true, length: { minimum: 3, maximum: 50 }

    validate :no_blank_unicode_in_username
    validate :no_links_in_username
    validate :username_not_fake_admin

    def no_blank_unicode_in_username
      not_valid = !username.scan(/[\u200B-\u200D\uFEFF]/).empty?
      if not_valid
        errors.add(:username, 'may not contain blank unicode characters')
      end
    end

    def no_links_in_username
      if %r{(?:http|ftp)s?://(?:\w+\.)+[a-zA-Z]{2,10}}.match?(username)
        errors.add(:username, 'cannot contain links')
        AuditLog.block_log(event_type: 'user_username_link_blocked',
                           comment: "username: #{username}")
      end
    end

    def username_not_fake_admin
      admin_badge = SiteSetting['AdminBadgeCharacter']
      mod_badge = SiteSetting['ModBadgeCharacter']

      [admin_badge, mod_badge].each do |badge|
        if badge.present? && username.include?(badge)
          errors.add(:username, "may not include the #{badge} character")
        end
      end
    end
  end
end
