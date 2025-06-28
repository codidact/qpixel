require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can delete post' do
    sign_in users(:deleter)

    before_history = PostHistory.where(post: posts(:question_two)).count
    post :delete, params: { id: posts(:question_two).id }
    after_history = PostHistory.where(post: posts(:question_two)).count

    assert_response(:found)
    assert_redirected_to post_path(assigns(:post))
    assert_nil flash[:danger]
    assert_equal before_history + 1, after_history, 'PostHistory event not created on deletion'
  end

  test 'delete requires authentication' do
    post :delete, params: { id: posts(:question_one).id }
    assert_redirected_to_sign_in
  end

  test 'unprivileged user cannot delete' do
    sign_in users(:closer)

    before_history = PostHistory.where(post: posts(:question_one)).count
    post :delete, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count

    assert_response(:found)
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a post with responses' do
    sign_in users(:deleter)

    before_history = PostHistory.where(post: posts(:question_one)).count
    post :delete, params: { id: posts(:question_one).id }
    after_history = PostHistory.where(post: posts(:question_one)).count

    assert_response(:found)
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a deleted post' do
    sign_in users(:deleter)

    before_history = PostHistory.where(post: posts(:deleted)).count
    post :delete, params: { id: posts(:deleted).id }
    after_history = PostHistory.where(post: posts(:deleted)).count

    assert_response(:found)
    assert_redirected_to post_path(assigns(:post))
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'cannot delete a locked post' do
    sign_in users(:deleter)

    before_history = PostHistory.where(post: posts(:locked)).count
    post :delete, params: { id: posts(:locked).id }
    after_history = PostHistory.where(post: posts(:locked)).count

    assert_response(:forbidden)
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on deletion'
  end

  test 'delete ensures all children are deleted' do
    parent = posts(:question_one)

    sign_in users(:moderator)

    assert_not_equal(0, parent.children.undeleted.count, 'Expected post to have undeleted children')

    before_history = PostHistory.where(post_id: parent.children.map(&:id)).count
    post :delete, params: { id: parent.id }
    after_history = PostHistory.where(post_id: parent.children.map(&:id)).count

    @post = assigns(:post)
    @post.reload

    assert_response(:found)
    assert_redirected_to post_path(@post)
    assert_nil flash[:danger]
    assert @post.children.all?(&:deleted), 'Expected all post children to be deleted as well'
    assert_equal before_history + parent.children.count, after_history,
                 'Expected deletion history events to be created for every child'
  end
end
