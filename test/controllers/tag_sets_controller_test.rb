require 'test_helper'

class TagSetsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should deny access to non-admins' do
    [:index, :global].each do |route|
      get route
      assert_response 404
    end
  rescue => e
    puts e.backtrace
  end

  test 'should allow admins to access index' do
    sign_in users(:admin)
    get :index
    assert_response 200
    assert_not_nil assigns(:tag_sets)
    assert_not_nil assigns(:counts)
  end

  test 'should deny admins access to global' do
    sign_in users(:admin)
    get :global
    assert_response 404
  end

  test 'should allow global admins to access global' do
    sign_in users(:global_admin)
    get :global
    assert_response 200
    assert_not_nil assigns(:tag_sets)
    assert_not_nil assigns(:counts)
  end

  test 'should allow admins to access show' do
    sign_in users(:global_admin)
    get :show, params: { id: tag_sets(:main).id, format: 'json' }
    assert_response 200
    assert_not_nil assigns(:tag_set)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  test 'should update tag set' do
    sign_in users(:global_admin)
    post :update, params: { id: tag_sets(:main).id, name: 'Test' }
    assert_response 200
    assert_not_nil assigns(:tag_set)
    assert_equal 'Test', assigns(:tag_set).name
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal 'success', JSON.parse(response.body)['status']
  end
end
