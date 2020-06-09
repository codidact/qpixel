require 'test_helper'

class ArticlesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get show article page' do
    get :show, params: { id: posts(:article_one).id }
    assert_not_nil assigns(:article)
    assert_response(200)
  end

  test 'should get show article page with deleted article' do
    sign_in users(:deleter)
    get :show, params: { id: posts(:deleted_article).id }
    assert_not_nil assigns(:article)
    assert_response(200)
  end

  test 'should prevent unprivileged user seeing deleted post' do
    get :show, params: { id: posts(:deleted_article).id }
    assert_response 404
  end

  test 'should get edit article page' do
    sign_in users(:editor)
    get :edit, params: { id: posts(:article_one).id }
    assert_not_nil assigns(:article)
    assert_response(200)
  end

  test 'should update existing article' do
    sign_in users(:editor)
    patch :update, params: { id: posts(:article_one).id, article: { title: 'ABCDEF GHIJKL MNOPQR',
                                                                    body_markdown: 'ABCDEF GHIJKL MNOPQR STUVWX YZ',
                                                                    tags_cache: ['discussion', 'support'] } }
    assert_not_nil assigns(:article)
    assert_equal ['discussion', 'support'], assigns(:article).tags_cache
    assert_equal ['discussion', 'support'], assigns(:article).tags.map(&:name)
    assert_response(302)
  end

  test 'should mark article deleted' do
    sign_in users(:deleter)
    delete :destroy, params: { id: posts(:article_one).id }
    assert_not_nil assigns(:article)
    assert_equal true, assigns(:article).deleted
    assert_response(302)
  end

  test 'should mark article undeleted' do
    sign_in users(:deleter)
    delete :undelete, params: { id: posts(:deleted_article).id }
    assert_not_nil assigns(:article)
    assert_equal false, assigns(:article).deleted
    assert_response(302)
  end
end
