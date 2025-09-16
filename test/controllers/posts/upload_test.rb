require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'upload should correctly check file types' do
    sign_in users(:standard_user)

    try_upload_file('not_uploadable.json', 'application/json')

    assert_response(:bad_request)
    assert_valid_json_response
    assert_not_nil JSON.parse(response.body)['message']

    try_upload_file('uploadable_png.png', 'image/png')

    assert_json_success
    assert_not_nil JSON.parse(response.body)['link']
  end

  private

  def try_upload_file(path, mime)
    post :upload, params: {
      file: file_fixture_upload(path, mime)
    }
  end
end
