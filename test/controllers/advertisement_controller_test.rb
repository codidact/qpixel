require 'test_helper'

class AdvertisementControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'index should return html' do
    get :index
    assert_response(:success)
    assert_equal 'text/html', response.media_type
  end

  test 'image paths should return png' do
    # Cannot test :random_question, as it requires initialization
    # of hot posts, which isn't provided via get helper.
    [:codidact, :community].each do |path|
      get path
      assert_response(:success)
      assert_equal 'image/png', response.media_type
    end
  end

  test 'post image path should return png' do
    get :specific_question, params: { id: posts(:question_one).id }
    assert_response(:success)
    assert_equal 'image/png', response.media_type
  end
end
