require 'test_helper'

class AdvertisementHelperTest < ActionView::TestCase
  include ApplicationHelper
  include AdvertisementHelper

  setup do
    @external_png = File.open(Rails.root.join('app/assets/images/logo.png'))
    stub_request(:get, 'https://example.com/external.png').to_return(body: @external_png)
  end

  teardown do
    @external_png.close
  end

  test ':community_icon should gracefully handle non-existent paths' do
    assert_nothing_raised do
      icon = community_icon('/assets/non-existent.jpeg')
      assert_nil icon
    end
  end

  test ':community_icon should correctly handle external URLs' do
    icon = community_icon('https://example.com/external.png')
    assert icon.is_a?(Magick::ImageList)
  end
end
