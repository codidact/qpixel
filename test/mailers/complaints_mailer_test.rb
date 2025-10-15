require 'test_helper'

class ComplaintsMailerTest < ActionMailer::TestCase
  test 'new_complaint' do
    email = ComplaintsMailer.with(complaint: complaints(:anonymous)).new_complaint
    assert_emails 1 do
      email.deliver_later
    end
    assert_operator email.from[0].length, :>, 3, 'Sender appears to be empty or default value'
  end

  test 'complaint_reviewed' do
    email = ComplaintsMailer.with(complaint: complaints(:reviewed)).complaint_reviewed
    assert_emails 1 do
      email.deliver_later
    end
    assert_operator email.from[0].length, :>, 3, 'Sender appears to be empty or default value'
  end
end
