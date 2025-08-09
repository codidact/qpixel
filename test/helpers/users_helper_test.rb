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

  test 'user_link should return placeholder link if user is nil' do
    link = Nokogiri::HTML4(user_link(nil)).at_css('a')
    assert_equal '#', link.attribute('href').value
    assert_equal 'deleted user', link.text
  end

  test 'user_link' do
    standard_user = users(:standard_user)

    expected = [
      [{
        href: "http://test.host/users/#{standard_user.id}",
        text: standard_user.rtl_safe_username
      }, standard_user]
    ]

    expected.each do |exp, usr|
      link = Nokogiri::HTML4(user_link(usr)).at_css('a')
      assert_equal exp[:href], link.attribute('href').value
      assert_equal exp[:text], link.text
    end
  end
end
