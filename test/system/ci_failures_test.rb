require 'application_system_test_case'

class CIFailuresTest < ApplicationSystemTestCase
  teardown :log_out

  test 'empty test to start with' do
    assert true
  end

  test 'temporary test to analyse CI failures what does basic user see in main' do
    category = categories(:main)
    log_in :basic_user
    visit category_path(category)
    assert_text 'Nonexistent to force screenshot'
  end

  test 'temporary test to analyse CI failures what does basic user see in main with log out first' do
    category = categories(:main)
    log_out
    log_in :basic_user
    visit category_path(category)
    assert_text 'Nonexistent to force screenshot'
  end

  test 'temporary test to analyse CI failures what does standard user see in main' do
    category = categories(:main)
    log_in :standard_user
    visit category_path(category)
    assert_text 'Nonexistent to force screenshot'
  end

  test 'temporary test to analyse CI failures what does standard user see after adding post to meta' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    post_title = 'Test title text for testing threads'
    create_post('Test body text for testing threads.', post_title)
    assert_text 'Unfollow new'  # Ensure post has finished saving to avoid timing problems

    log_out
    log_in :standard_user
    visit category_path(category)
    assert_text 'Nonexistent to force screenshot'
  end
end
