require 'test_helper'

class FlagMailerTest < ActionMailer::TestCase
  test 'flag_escalated' do
    assert_emails 1 do
      FlagMailer.with(flag: flags(:escalated)).flag_escalated.deliver_now
    end
  end
end
