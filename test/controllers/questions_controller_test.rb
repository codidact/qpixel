require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ApplicationTestHelper

  test 'should get tagged page' do
    get :tagged, params: { tag: 'discussion', tag_set: tag_sets(:main).id }
    assert_not_nil assigns(:questions)
    assert_response(200)
  end
end
