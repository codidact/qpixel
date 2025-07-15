require 'test_helper'

class AdvertisementControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'index should return html' do
    get :index
    assert_response(:success)
    assert_equal 'text/html', response.media_type
  end

  test 'image paths should return png' do
    [:codidact, :community, :random_question, :promoted_post].each do |path|
      get path
      assert_response(:success)
      assert_equal 'image/png', response.media_type
    end
  end

  test 'specific_question for different post types' do
    { 123456789 => :not_found,
      posts(:question_one).id => :success,
      posts(:article_one).id => :success,
      posts(:answer_one).id => :not_found
    }.each do |id, status|
      try_specific_question(id)
      assert_response(status)
      if status == :success
        assert_equal 'image/png', response.media_type
      end
    end
  end

  test 'specific_category' do
    # :specific_category uses random post selection, so we can't easily test for different post types
    get :specific_category, params: { id: categories(:main).id }
    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  private

  def try_specific_question(id)
    get :specific_question, params: { id: id }
  end
end
