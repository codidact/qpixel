require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "users should be destructible in a single call" do
    assert_nothing_raised do
      users(:standard_user).destroy!
    end
  end
end
