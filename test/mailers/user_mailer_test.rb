require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test 'deletion_confirmation' do
    email = UserMailer.with(user: users(:standard_user), host: communities(:sample).host)
                      .deletion_confirmation
    assert_emails 1 do
      email.deliver_later
    end
    assert_operator email.from[0].length, :>, 3, 'Sender for deletion confirmation appears empty or default value'
  end
end
