require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can save draft' do
    sign_in users(:standard_user)
    post :save_draft, params: {
      body: 'test_body',
      comment: 'test_comment',
      excerpt: 'test_excerpt',
      license: '4',
      path: 'test_path',
      tags: ['tag1', 'tag2'],
      title: 'test_title'
    }
    assert_response 200
    assert_nothing_raised do
      JSON.parse(response.body)
    end

    base_key = JSON.parse(response.body)['key']

    assert_equal "saved_post.#{users(:standard_user).id}.test_path", base_key
    assert_equal 'test_body', RequestContext.redis.get(base_key)
    assert_equal 'test_comment', RequestContext.redis.get("#{base_key}.comment")
    assert_equal 'test_excerpt', RequestContext.redis.get("#{base_key}.excerpt")
    assert_equal '4', RequestContext.redis.get("#{base_key}.license")
    assert_empty ['tag1', 'tag2'].difference(RequestContext.redis.smembers("#{base_key}.tags"))
    assert_equal 'test_title', RequestContext.redis.get("#{base_key}.title")
  end

  test 'can delete draft' do
    sign_in users(:standard_user)
    post :delete_draft, params: { path: 'test' }
    assert_response 200
  end
end
