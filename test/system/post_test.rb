require 'application_system_test_case'

class PostTest < ApplicationSystemTestCase
  # -------------------------------------------------------
  # Create
  # -------------------------------------------------------

  test 'Not-signed in user cannot create a post' do
    visit root_url
    click_on 'Create Post'

    assert_current_path new_user_session_url
  end

  test 'Signed in user can create a question' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    click_on 'Create Post'

    body_text = 'When running QPixel, users are generally supposed to be able to create posts. ' \
                'Does that actually work?'
    title_text = 'Can a signed-in user create a post?'

    fill_in 'Body', with: body_text
    fill_in 'Summarize your post with a title:', with: title_text
    post_form_select_tag tags(:faq).name

    # Check that the post is actually created
    assert_difference 'Post.count' do
      click_on "Save Post in #{category.name}"
    end

    # Verify that the post is correctly created
    new_post = Post.last
    assert_equal body_text, new_post.body_markdown
    assert_equal title_text, new_post.title
    assert_equal [tags(:faq)], new_post.tags
  end

  test 'Creating a question is blocked when body is too short' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    click_on 'Create Post'

    fill_in 'Summarize your post with a title:', with: 'Initial title is of sufficient length'
    post_form_select_tag tags(:faq).name
    fill_in 'Body', with: 'Short'

    # Check that the button is disabled
    find_button "Save Post in #{category.name}", disabled: true

    # After filling out body correctly, verify that the button becomes enabled
    fill_in 'Body', with: 'This body should pass the minimum length requirements for questions in the meta category.'
    find_button "Save Post in #{category.name}", disabled: false
  end

  test 'Creating a question is blocked when title is too short' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    click_on 'Create Post'

    fill_in 'Body', with: 'This body should pass the minimum length requirements for questions in the meta category.'
    post_form_select_tag tags(:faq).name
    fill_in 'Summarize your post with a title:', with: 'Too short'

    # Check that the button is disabled
    find_button "Save Post in #{category.name}", disabled: true

    # After filling out the title, verify that the button becomes enabled
    fill_in 'Summarize your post with a title:', with: 'Updated title is of sufficient length'
    find_button "Save Post in #{category.name}", disabled: false
  end

  test 'Signed in user gets to pick post type for post creation in categories with multiple types' do
    category = categories(:main)
    log_in :standard_user
    visit category_path(category)
    click_on 'Create Post'

    # All the top level post types set should be present
    category.post_types.where(is_top_level: true).each do |pt|
      assert_link pt.name.underscore.humanize
    end

    # Pick a non-question post type
    post_type = category.post_types.where(is_top_level: true).where.not(name: 'Question').first

    # After clicking on a post type, we should be on the creation page of the correct category and post type.
    click_on post_type.name.underscore.humanize
    assert_current_path new_category_post_url(post_type.id, category.id)
  end

  test 'Signed in user can answer question' do
    log_in :standard_user
    post = posts(:question_two)
    visit post_path(post)

    # Answer the question
    answer_text = 'You can do this by running the rails system tests, rails test:system.'
    fill_in 'Body', with: answer_text
    assert_difference 'Post.count' do
      click_on "Save Post in #{post.category.name}"
    end

    # We should now be looking at our answer, look for the text on the page
    assert_text answer_text

    # The original post should also still be on the page
    assert_text post.body
  end

  # -------------------------------------------------------
  # Show
  # -------------------------------------------------------

  test 'Anyone can view question' do
    post = posts(:question_one)
    visit post_url(post)

    # Check that the post is displayed somewhere on the page
    assert_text post.title
    assert_text post.body

    # Check that answers are displayed somewhere on the page
    assert post.children.any?, 'The post for this system test should have answers'
    post.children.where(deleted: false).each do |child|
      assert_text child.body
    end
  end

  test 'Anyone can sort answers' do
    post = posts(:question_one)
    visit post_url(post)

    click_on 'Active'

    assert_current_path post_url(post, sort: 'active')
  end

  # -------------------------------------------------------
  # Edit
  # -------------------------------------------------------

  test 'User with edit permissions can directly edit question' do
    log_in :editor
    post = posts(:question_two)
    visit post_url(post)

    within ".post[data-post-id=\"#{post.id}\"]" do
      click_on 'Edit'
    end

    updated_text = 'This is the updated body text, which should be quite different from the original text!'
    fill_in 'Body', with: updated_text
    fill_in 'Edit Comment', with: 'Major Rewrite for Tests'

    click_on "Save Post in #{post.category.name}"
    assert_current_path post_url(post)

    # Check that the page shows the updated text
    assert_text updated_text
  end
end
