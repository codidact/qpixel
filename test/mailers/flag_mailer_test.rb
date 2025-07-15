require 'test_helper'

class FlagMailerTest < ActionMailer::TestCase
  test 'flag_escalated should correctly send flag escalation emails' do
    assert_emails 1 do
      flag = flags(:escalated)

      FlagMailer.with(flag: flag).flag_escalated.deliver_now
    end
  end

  test 'flag_escalated should not fail if the flagged post has been updated before escalation' do
    assert_emails 1 do
      flag = flags(:escalated)

      # forces 'post modified after flag' to be rendered
      flag.post.update(updated_at: DateTime.now)

      FlagMailer.with(flag: flag).flag_escalated.deliver_now
    end
  end
end
