require 'test_helper'

class FlagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should create new post flag' do
    sign_in users(:standard_user)
    post :new, params: { reason: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', post_id: posts(:answer_two).id, post_type: 'Post' }

    assert_not_nil assigns(:flag)
    assert_not_nil assigns(:flag).post
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(:created)
  end

  test 'should create new comment flag' do
    sign_in users(:standard_user)
    post :new, params: { reason: 'ABCDEF GHIJKL MNOPQR STUVWX YZ', post_id: comments(:one).id, post_type: 'Comment' }

    assert_not_nil assigns(:flag)
    assert_not_nil assigns(:flag).post
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(:created)
  end

  test 'should retrieve flag queue' do
    sign_in users(:moderator)
    get :queue
    assert_not_nil assigns(:flags)
    assert_response(:success)
  end

  test 'should add status to flag' do
    sign_in users(:moderator)
    post :resolve, params: { id: flags(:one).id, result: 'ABCDEF', message: 'ABCDEF GHIJKL MNOPQR STUVWX YZ' }

    assert_not_nil assigns(:flag)
    assert_not_nil assigns(:flag).status
    assert_not_nil assigns(:flag).handled_by
    assert_equal 'success', JSON.parse(response.body)['status']
    assert_response(:success)
  end

  test 'should require authentication to create flag' do
    sign_out :user
    post :new
    assert_response(:found)
  end

  test 'should require authentication to get queue' do
    sign_out :user
    get :queue
    assert_response(:found)
  end

  test 'should require moderator status to get queue' do
    sign_in users(:standard_user)
    get :queue
    assert_response(:not_found)
  end

  test 'should require authentication to resolve flag' do
    sign_out :user
    post :resolve, params: { id: flags(:one).id }
    assert_response(:found)
  end

  test 'should require moderator status to resolve flag' do
    sign_in users(:standard_user)
    post :resolve, params: { id: flags(:one).id }
    assert_response(:not_found)
  end

  test 'should not allow non-moderator users to resolve flags on themselves' do
    sign_in users(:deleter)
    post :resolve, params: { id: flags(:on_deleter).id }
    assert_response(:not_found)
  end

  test 'should not allow non-moderator users to resolve confidential flags' do
    sign_in users(:deleter)
    post :resolve, params: { id: flags(:confidential_on_deleter).id }
    assert_response(:not_found)
  end

  test 'should get handled flags list' do
    sign_in users(:moderator)
    get :handled
    assert_response :success
    assert_not_nil assigns(:flags)
  end

  test 'should require authentication to get handled flags list' do
    get :handled
    assert_response :found
  end

  test 'should require moderator status to get handled flags list' do
    sign_in users(:standard_user)
    get :handled
    assert_response(:not_found)
  end

  test 'non-moderator users should only see their flag history' do
    mod_user = users(:moderator)
    std_user = users(:standard_user)

    sign_in std_user
    get :history, params: { id: mod_user.id }
    assert_response(:not_found)

    get :history, params: { id: std_user.id }
    assert_response(:success)

    sign_in mod_user
    get :history, params: { id: std_user.id }
    assert_response(:success)
  end
end
