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

  test 'Signed in user can create a post' do
    category = categories(:meta)
    log_in :standard_user
    visit category_path(category)
    click_on 'Create Post'

    fill_in 'Body', with: "When running QPixel, users are generally supposed to be able to create posts.\n" \
                          'Does that actually work?'
    fill_in 'Summarize your post with a title:', with: 'Can a signed-in user create a post?'
    post_form_select_tag tags(:faq).name

    # Check that the post is actually created
    assert_difference 'Post.count' do
      click_on "Save Post in #{category.name}"
    end
  end

  # TODO: Post validations

  # -------------------------------------------------------
  # Show
  # -------------------------------------------------------

  test 'User can view post' do
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

  test 'User can sort answers' do
    post = posts(:question_one)
    visit post_url(post)

    click_on 'Active'

    assert_current_path post_url(post, sort: 'active')
  end
end
