require 'test_helper'

class FakeCommunityControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'proper community should not access fake community controller' do
    RequestContext.community = communities(:sample)
    request.env['HTTP_HOST'] = 'sample.qpixel.com'

    get(:communities)
    assert_response(:not_found)
  end

  test 'fake community should be able to access fake community controller' do
    RequestContext.community = communities(:fake)
    request.env['HTTP_HOST'] = 'fake.qpixel.com'

    get(:communities)
    assert_response(:success)
    assert_not_nil assigns(:communities)
  end
end
