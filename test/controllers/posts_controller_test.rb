require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to get new_help' do
    get :new_help
    assert_response 302
  end

  test 'should require authentication to get edit_help' do
    get :edit_help, params: { id: posts(:policy_doc).id }
    assert_response 302
  end

  test 'should deny regular users access to new_help' do
    sign_in users(:standard_user)
    get :new_help
    assert_response 404
  end

  test 'should deny regular users access to edit_help' do
    sign_in users(:standard_user)
    get :edit_help, params: { id: posts(:policy_doc).id }
    assert_response 404
  end

  test 'should allow moderators access to new_help' do
    sign_in users(:moderator)
    get :new_help
    assert_response 200
  end

  test 'should allow moderators access to edit_help' do
    sign_in users(:moderator)
    get :edit_help, params: { id: posts(:help_doc).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'should disallow regular users to create help doc' do
    sign_in users(:standard_user)
    post :create_help, params: { post: { post_type_id: HelpDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                         title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'help-doc' } }
    assert_response 404
  end

  test 'should allow moderators to create help doc' do
    sign_in users(:moderator)
    post :create_help, params: { post: { post_type_id: HelpDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                         title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'help-doc' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should disallow moderators to create policy doc' do
    sign_in users(:moderator)
    post :create_help, params: { post: { post_type_id: PolicyDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                         title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'policy-doc' } }
    assert_response 403
    assert_nil assigns(:post).id
    assert_equal true, assigns(:post).errors.any?
  end

  test 'should allow admins to create policy doc' do
    sign_in users(:admin)
    post :create_help, params: { post: { post_type_id: PolicyDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                         title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'policy-doc' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should disallow regular users to edit help doc' do
    sign_in users(:standard_user)
    patch :update_help, params: { id: posts(:help_doc).id,
                                  post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 404
  end

  test 'should allow moderators to edit help doc' do
    sign_in users(:moderator)
    patch :update_help, params: { id: posts(:help_doc).id,
                                  post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should disallow moderators to edit policy doc' do
    sign_in users(:moderator)
    patch :update_help, params: { id: posts(:policy_doc).id,
                                  post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 404
  end

  test 'should allow admins to edit policy doc' do
    sign_in users(:admin)
    patch :update_help, params: { id: posts(:policy_doc).id,
                                  post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should successfully get help center' do
    get :help_center
    assert_response 200
    assert_not_nil assigns(:posts)
  end

  test 'question permalink should correctly redirect' do
    get :share_q, params: { id: posts(:question_one).id }
    assert_response 302
    assert_redirected_to question_path(posts(:question_one))
  end

  test 'answer permalink should correctly redirect' do
    get :share_a, params: { qid: posts(:question_one).id, id: posts(:answer_one).id }
    assert_response 302
    assert_redirected_to question_path(id: posts(:question_one).id, anchor: "answer-#{posts(:answer_one).id}")
  end

  test 'should require sign in to write post' do
    get :new, params: { category_id: categories(:main).id, post_type_id: post_types(:question).id }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should require sign in to create post' do
    post :create, params: { category_id: categories(:main).id, post_type_id: post_types(:question).id,
                            post: { body_markdown: 'ABCD EFGH IJKL MNOP QRST UVWX YZ', title: 'ABCD EFGH IJKL M',
                                    tags_cache: ['discussion', 'support', 'bug', 'feature-request'] } }
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'should allow signed in user to write post' do
    sign_in users(:standard_user)
    get :new, params: { category_id: categories(:main).id, post_type_id: post_types(:question).id }
    assert_response 200
    assert_not_nil assigns(:post)
    assert_equal categories(:main).id, assigns(:post).category_id
    assert_equal post_types(:question).id, assigns(:post).post_type_id
  end

  test 'should allow signed in user to create post' do
    sign_in users(:standard_user)
    post :create, params: { category_id: categories(:main).id, post_type_id: post_types(:question).id,
                            post: { body_markdown: 'ABCD EFGH IJKL MNOP QRST UVWX YZ', title: 'ABCD EFGH IJKL M',
                                    tags_cache: ['discussion', 'support', 'bug', 'feature-request'] } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_empty assigns(:post).errors.full_messages
    assert_redirected_to question_path(assigns(:post))
  end

  test 'should prevent user with insufficient trust level posting when category requires higher' do
    sign_in users(:standard_user)
    post :create, params: { category_id: categories(:high_trust).id, post_type_id: post_types(:question).id,
                            post: { body_markdown: 'ABCD EFGH IJKL MNOP QRST UVWX YZ', title: 'ABCD EFGH IJKL M',
                                    tags_cache: ['discussion', 'support', 'bug', 'feature-request'] } }
    assert_response 403
    assert_not_nil assigns(:post)
    assert_equal true, assigns(:post).errors.any?
    assert_equal true, assigns(:post).errors.full_messages[0].start_with?("You don't have a high enough trust level")
  end
end
