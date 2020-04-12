require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    get :index
    assert_response 200
    assert_not_nil assigns(:categories)
  end

  test 'should get show' do
    get :show, params: { id: categories(:main).id }
    assert_response 200
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:posts)
    assert_not_empty assigns(:posts)
  end
end
