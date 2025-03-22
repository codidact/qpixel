require 'application_system_test_case'

class ThreadTest < ApplicationSystemTestCase
  test 'post author can unfollow and follow new comment threads' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    create_post('Test body text for testing threads.', 'Test title text for testing threads')

    assert_text 'Unfollow new'
    click_on 'Unfollow new'
    assert_text 'Follow new'
    click_on 'Follow new'
    assert_text 'Unfollow new'
  end

  test 'other can follow and unfollow new comment threads' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    post_title_text = 'Test title text for testing threads'
    create_post('Test body text for testing threads.', post_title_text)

    log_out
    log_in :basic_user
    visit category_path(category)
    click_on post_title_text

    assert_text 'Follow new'
    click_on 'Follow new'
    assert_text 'Unfollow new'
    click_on 'Unfollow new'
    assert_text 'Follow new'
  end

  test 'auto follow comment threads tick causes following threads commented in' do
    category = categories(:meta)
    log_in :basic_user
    visit category_path(category)
    post_body = 'Test body text for testing threads.'
    post_title = 'Test title text for testing threads'
    create_post post_body, post_title
    thread_body = 'Test comment text for testing adding to a comment thread.'
    thread_title = 'Auto followed comment thread'
    create_thread thread_body, thread_title

    log_out
    log_in :editor
    visit category_path(category)
    click_on post_title
    click_on thread_title
    create_comment 'Test comment text for testing adding to a comment thread.'
    assert_text 'unfollow'

    log_out
    log_in :basic_user
    visit category_path(category)
    click_on post_title
    click_on thread_title
    create_comment('Test comment text for testing adding to a comment thread.')

    log_out
    log_in :editor
    assert_notification "There are new comments in a followed thread '#{thread_title}'"
  end

  test 'no auto follow comment threads tick causes not following threads commented in' do
    category = categories(:meta)
    log_in :basic_user
    visit category_path(category)
    post_body = 'Test body text for testing threads.'
    post_title = 'Test title text for testing threads'
    create_post post_body, post_title
    thread_body = 'Test comment body text for testing adding to a comment thread.'
    thread_title = 'Not auto followed comment thread'
    create_thread thread_body, thread_title

    log_out
    log_in :editor
    click_on 'Manage profile'
    click_on 'Preferences'
    uncheck 'Auto follow comment threads'
    visit category_path(category)
    click_on post_title
    click_on thread_title
    create_comment 'Test comment text for testing adding to a comment thread.'
    assert_text 'follow'

    log_out
    log_in :basic_user
    visit category_path(category)
    click_on post_title
    click_on thread_title
    create_comment 'Test comment text for testing adding to a comment thread.'

    log_out
    log_in :editor
    assert_no_notification "There are new comments in a followed thread '#{thread_title}'"
  end


end
