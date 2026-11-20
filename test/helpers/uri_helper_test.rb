require 'test_helper'

class UriHelperTest < ActionView::TestCase
  include Devise::Test::ControllerHelpers

  test ':force_safe_uri should correctly handle URIs' do
    expected = [
      ['/relative', '/relative'],
      ['http://example.com', 'http://example.com'],
      ['https://example.com', 'https://example.com'],
      ['localhost:3000', 'http://localhost:3000']
    ]

    expected.each do |input, expected|
      actual = force_safe_uri(input)
      assert_equal expected, actual
    end
  end
end
