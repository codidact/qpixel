require 'test_helper'

class CloseReasonTest < ActiveSupport::TestCase
  test ':accessible_to should let global admins access all close reasons' do
    accessible = CloseReason.accessible_to(users(:global_admin))
    assert CloseReason.unscoped.size, accessible.size
  end

  test ':accessible_to should correctly handle non-community scoped contexts' do
    RequestContext.community = nil

    users.each do |user|
      accessible = CloseReason.accessible_to(user)

      if user.global_admin?
        assert_equal CloseReason.unscoped.size, accessible.size
      else
        assert_equal 0, accessible.size
      end
    end
  end
end
