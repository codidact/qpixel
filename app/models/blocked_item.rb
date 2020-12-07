class BlockedItem < ApplicationRecord
  scope :active, -> { where('expires IS NULL OR expires > NOW()') }

  # Allow for easy checking of type
  ['ip', 'email', 'email_host'].each do |bt|
    define_method "#{bt.underscore}?" do
      item_type == bt
    end
    scope "#{bt}s".to_sym, -> { active.where(item_type: bt) }
  end
end
