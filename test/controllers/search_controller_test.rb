require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'get without a search term should result in nil' do
    get :search
    assert_response 200
    assert_nil assigns(:posts)
  end

  test 'get with a search term should have results' do
    get :search, params: { search: 'ABCDEF' }
    assert_response 200
    assert_not_nil assigns(:posts)
  end

  test 'all search orders should work' do
    ['relevance', 'score', 'age'].each do |so|
      get :search, params: { search: 'ABCDEF', sort: so }
      assert_response 200
      assert_not_nil assigns(:posts)
    end
  end

  test 'undefined search order should not error' do
    assert_nothing_raised do
      get :search, params: { search: 'ABCDEF', sort: 'abcdef' }
      assert_response 200
      assert_not_nil assigns(:posts)
    end
  end

  test 'search with qualifiers should work' do
    assert_nothing_raised do
      get :search, params: { search: 'score:>=1 created:<1y abcdef' }
      assert_response 200
      assert_not_nil assigns(:posts)
    end
  end
end
