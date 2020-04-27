require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'index with json format should return JSON list of tags' do
    get :index, params: { format: 'json' }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_not_nil assigns(:tags)
  end

  test 'index with search params should return tags starting with search' do
    get :index, params: { format: 'json', term: 'dis' }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_not_nil assigns(:tags)
    JSON.parse(response.body).each do |tag|
      assert_equal true, tag['name'].start_with?('dis')
    end
  end
end
