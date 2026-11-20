require 'test_helper'

class TwoFactorMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  test 'disable_email should correctly send emails' do
    com_usr = communities(:sample)
    std_usr = users(:standard_user)

    email = TwoFactorMailer.with(user: std_usr, host: com_usr.host)
                           .disable_email

    assert_emails 1 do
      email.deliver_later
    end

    token_uri = two_factor_disable_link_url(token: '', host: com_usr.host)

    assert email.subject.include?(SiteSetting['NetworkName'])
    assert_select_email do
      assert_select "a[href^='#{token_uri}']"
    end
  end

  test 'login_email should correctly send emails' do
    com_usr = communities(:sample)
    std_usr = users(:standard_user)

    email = TwoFactorMailer.with(user: std_usr, host: com_usr.host)
                           .login_email

    assert_emails 1 do
      email.deliver_later
    end

    qr_uri = qr_login_url(token: '', host: com_usr.host)

    assert email.subject.include?(SiteSetting['NetworkName'])
    assert_select_email do
      assert_select "a[href^='#{qr_uri}']"
    end
  end

  test 'backup_code should correctly send emails' do
    com_usr = communities(:sample)
    std_usr = users(:standard_user)

    email = TwoFactorMailer.with(user: std_usr, host: com_usr.host)
                           .backup_code

    assert_emails 1 do
      email.deliver_later
    end

    backup_uri = two_factor_status_url(host: com_usr.host)

    assert email.subject.include?(SiteSetting['NetworkName'])
    assert_select_email do
      assert_select "a[href^='#{backup_uri}']"
    end
  end
end
