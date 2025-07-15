require 'test_helper'

class FlagMailerTest < ActionMailer::TestCase
  test 'flag_escalated' do
    assert_emails 1 do
      flag = flags(:escalated)

      # forces 'post modified after flag' to be rendered
      flag.post.update(updated_at: DateTime.now)

      FlagMailer.with(flag: flags(:escalated)).flag_escalated.deliver_now
    end
  end
end
