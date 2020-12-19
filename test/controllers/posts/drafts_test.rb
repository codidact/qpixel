require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can save draft' do
    sign_in users(:standard_user)
    post :save_draft, params: { path: 'test', post: 'test' }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end
    assert_equal "saved_post.#{users(:standard_user).id}.test", JSON.parse(response.body)['key']
    assert_equal 'test', RequestContext.redis.get(JSON.parse(response.body)['key'])
  end

  test 'can delete draft' do
    sign_in users(:standard_user)
    post :delete_draft, params: { path: 'test' }
    assert_response 200
  end
end
