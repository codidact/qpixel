require 'application_system_test_case'

class CIFailuresTest < ApplicationSystemTestCase
  test 'empty test to start with' do
    assert true
  end


  test 'Anyone can view question' do
    post = posts(:question_one)
    visit post_url(post)
    # category=categories(:main)
    # visit category_path(category)

    assert_text 'Nonexistent to force screenshot'
  end

  test 'temporary test to analyse CI failures what does main look like before logging in' do
    clear_cache
    category = categories(:main)
    visit category_path(category)
    assert_text 'Nonexistent to force screenshot'
  end

  test 'temporary test to analyse CI failures what does basic user see in main' do
    category = categories(:main)
    log_in :basic_user
    visit category_path(category)
    assert_text 'Nonexistent to force screenshot'
  end

  test 'temporary test to analyse CI failures what does basic user see in main with log out first' do
    category = categories(:main)
    visit category_path(category)
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

  test 'temporary test to analyse CI failures what does basic user see after adding post to main' do
    category = categories(:main)
    log_in :standard_user
    visit category_path(category)
    button_label = 'Create Post'
    post_body = 'Test body text for testing threads.'
    post_title = 'Test title text for testing threads'
    tags = ['bug']
    create_post(button_label, post_body, post_title, tags)
    assert_text 'Unfollow new'  # Ensure post has finished saving to avoid timing problems

    log_out
    assert_text 'Sign in'

    log_in :basic_user
    visit category_path(category)
    assert_text '0 posts'
  end
end
