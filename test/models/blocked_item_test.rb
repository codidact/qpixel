require 'test_helper'

class BlockedItemTest < ActiveSupport::TestCase
  test 'predicates should correctly check item type' do
    ['email', 'ip'].each do |type|
      assert blocked_items(type.to_sym).send("#{type}?")
    end
  end
end
