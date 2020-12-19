require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can update post' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:question_one)).count
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal sample.edit.body_markdown, assigns(:post).body_markdown
    assert_equal before_history + 1, after_history, 'No PostHistory event created on author update'
  end

  test 'moderators can update post' do
    sign_in users(:moderator)
    before_history = PostHistory.where(post: posts(:question_one)).count
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal sample.edit.body_markdown, assigns(:post).body_markdown
    assert_equal before_history + 1, after_history, 'No PostHistory event created on moderator update'
  end

  test 'update requires authentication' do
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'update by unprivileged user generates suggested edit' do
    sign_in users(:closer)
    before_history = PostHistory.where(post: posts(:question_one)).count
    before_edits = SuggestedEdit.where(post: posts(:question_one)).count
    before_body = posts(:question_one).body_markdown
    patch :update, params: { id: posts(:question_one).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    after_edits = SuggestedEdit.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_equal before_body, assigns(:post).body_markdown, 'Suggested edit incorrectly applied immediately'
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on unprivileged update'
    assert_equal before_edits + 1, after_edits, 'No SuggestedEdit created on unprivileged update'
  end

  test 'update rejects no change edit' do
    sign_in users(:standard_user)
    post = posts(:question_one)
    before_history = PostHistory.where(post: post).count
    patch :update, params: { id: post.id,
                             post: { title: post.title, body_markdown: post.body_markdown,
                                     tags_cache: post.tags_cache } }
    after_history = PostHistory.where(post: posts(:question_one)).count
    assert_response 302
    assert_redirected_to post_path(posts(:question_one))
    assert_not_nil assigns(:post)
    assert_not_nil flash[:danger]
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on no-change update'
  end

  test 'cannot update locked post' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:locked)).count
    patch :update, params: { id: posts(:locked).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:locked)).count
    assert_response 403
    assert_equal before_history, after_history, 'PostHistory event incorrectly created on update'
  end

  test 'anyone with unrestricted can update free-edit post' do
    sign_in users(:standard_user)
    before_history = PostHistory.where(post: posts(:free_edit)).count
    patch :update, params: { id: posts(:free_edit).id,
                             post: { title: sample.edit.title, body_markdown: sample.edit.body_markdown,
                                     tags_cache: sample.edit.tags_cache } }
    after_history = PostHistory.where(post: posts(:free_edit)).count
    assert_response 302
    assert_redirected_to post_path(posts(:free_edit))
    assert_not_nil assigns(:post)
    assert_equal sample.edit.body_markdown, assigns(:post).body_markdown
    assert_equal before_history + 1, after_history, 'No PostHistory event created on free-edit update'
  end
end
