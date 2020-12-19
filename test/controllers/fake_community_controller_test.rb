require 'test_helper'

class FakeCommunityControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'proper community should not access fake community controller' do
    RequestContext.community = communities(:sample)
    request.env['HTTP_HOST'] = 'sample.qpixel.com'

    get(:communities)
    assert_response(404)
  end

  test 'fake community should be able to access fake community controller' do
    RequestContext.community = communities(:fake)
    request.env['HTTP_HOST'] = 'fake.qpixel.com'

    get(:communities)
    assert_response(200)
    assert_not_nil assigns(:communities)
  end
end
