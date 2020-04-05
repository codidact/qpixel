require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should require authentication to get new' do
    get :new
    assert_response 302
  end

  test 'should require authentication to get edit' do
    get :edit, params: { id: posts(:policy_doc).id }
    assert_response 302
  end

  test 'should deny regular users access to new' do
    sign_in users(:standard_user)
    get :new
    assert_response 404
  end

  test 'should deny regular users access to edit' do
    sign_in users(:standard_user)
    get :edit, params: { id: posts(:policy_doc).id }
    assert_response 404
  end

  test 'should allow moderators access to new' do
    sign_in users(:moderator)
    get :new
    assert_response 200
  end

  test 'should allow moderators access to edit' do
    sign_in users(:moderator)
    get :edit, params: { id: posts(:help_doc).id }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'should disallow regular users to create help doc' do
    sign_in users(:standard_user)
    post :create, params: { post: { post_type_id: HelpDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                    title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'help-doc' } }
    assert_response 404
  end

  test 'should allow moderators to create help doc' do
    sign_in users(:moderator)
    post :create, params: { post: { post_type_id: HelpDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                    title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'help-doc' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should disallow moderators to create policy doc' do
    sign_in users(:moderator)
    post :create, params: { post: { post_type_id: PolicyDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                    title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'policy-doc' } }
    assert_response 200
    assert_nil assigns(:post).id
    assert_equal true, assigns(:post).errors.any?
  end

  test 'should allow admins to create policy doc' do
    sign_in users(:admin)
    post :create, params: { post: { post_type_id: PolicyDoc.post_type_id, body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                    title: 'ABCDEF GHIJKL MNOPQR', doc_slug: 'policy-doc' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should disallow regular users to edit help doc' do
    sign_in users(:standard_user)
    patch :update, params: { id: posts(:help_doc).id,
                             post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 404
  end

  test 'should allow moderators to edit help doc' do
    sign_in users(:moderator)
    patch :update, params: { id: posts(:help_doc).id,
                             post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 302
    assert_not_nil assigns(:post)
    assert_not_nil assigns(:post).id
  end

  test 'should disallow moderators to edit policy doc' do
    sign_in users(:moderator)
    patch :update, params: { id: posts(:policy_doc).id,
                             post: { body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', title: 'ABCDEF GHIJKL MNOPQR' } }
    assert_response 404
  end

  test 'should allow admins to edit policy doc' do
    sign_in users(:admin)
    patch :update, params: { id: posts(:policy_doc).id,
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
end
