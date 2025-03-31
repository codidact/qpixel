require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  include Devise::Test::ControllerHelpers

  test 'avatar_url' do
    expected = [
      ["http://test.host/users/#{users(:standard_user).id}/avatar/16.png", users(:standard_user)],
      ['http://test.host/users/avatar/X/%23E73737FF/16.png', nil],
      ['http://test.host/users/avatar/X/%23E73737FF/16.png', users(:deleted_account)],
      ['http://test.host/users/avatar/X/%23E73737FF/16.png', users(:deleted_profile)]
    ]
    expected.each do |exp, usr|
      assert_equal exp, avatar_url(usr)
    end
  end
end
