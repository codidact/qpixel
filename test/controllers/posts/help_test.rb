require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can get help center' do
    get :help_center
    assert_response 200
    assert_not_nil assigns(:posts)
  end

  test 'can get help article' do
    get :document, params: { slug: posts(:help_article).doc_slug }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'moderator can get mod help article' do
    sign_in users(:moderator)
    get :document, params: { slug: posts(:mod_help_article).doc_slug }
    assert_response 200
    assert_not_nil assigns(:post)
  end

  test 'moderator help requires authentication' do
    get :document, params: { slug: posts(:mod_help_article).doc_slug }
    assert_response 404
    assert_not_nil assigns(:post)
  end

  test 'regular user cannot get mod help' do
    sign_in users(:standard_user)
    get :document, params: { slug: posts(:mod_help_article).doc_slug }
    assert_response 404
    assert_not_nil assigns(:post)
  end

  test 'cannot get disabled help article' do
    sign_in users(:moderator)
    get :document, params: { slug: posts(:disabled_help_article).doc_slug }
    assert_response 404
    assert_not_nil assigns(:post)
  end
end
