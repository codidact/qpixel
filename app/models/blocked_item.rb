class BlockedItem < ApplicationRecord

  # Allow for easy checking of type
  ['ip', 'email', 'email_host'].each do |bt|
    define_method "#{pt.underscore}?" do
      type == bt
    end
  end
end
