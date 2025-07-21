require 'test_helper'

class AdminMailerTest < ActionMailer::TestCase
  test 'to_moderators' do
    email = AdminMailer.with(body_markdown: 'test', subject: 'test', community: communities(:sample)).to_moderators
    assert_emails 1 do
      email.deliver_later
    end
    assert_operator email.from[0].length, :>, 3, 'Sender appears to be empty or default value'
  end

  test 'to_all_users' do
    email = AdminMailer.with(body_markdown: 'test', subject: 'test', users: ['test1@example.com'],
                             community: communities(:sample))
                       .to_all_users
    assert_emails 1 do
      email.deliver_later
    end
    assert_operator email.from[0].length, :>, 3, 'Sender appears to be empty or default value'
  end
end
