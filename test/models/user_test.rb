require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "users should be destructible in a single call" do
    assert_nothing_raised do
      users(:standard_user).destroy!
    end
  end

  test "has_privilege should check against reputation for a standard user" do
    assert_equal false, users(:standard_user).has_privilege?('Close')
    assert_equal true, users(:closer).has_privilege?('Close')
  end

  test "has_privilege should grant all to admins and moderators" do
    assert_equal true, users(:moderator).has_privilege?('Delete')
    assert_equal true, users(:admin).has_privilege?('Delete')
  end

  test "has_post_privilege should grant all to OP" do
    assert_equal true, users(:standard_user).has_post_privilege?('Delete', posts(:question_one))
  end
end
