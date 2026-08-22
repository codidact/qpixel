require 'test_helper'

class ModeratorHelperTest < ActionView::TestCase
  test 'split_hash_ip works as expected' do
    test_data = [
      ['127.0.0.1', ['IPv4',
                     ['e12e3aff07586c2a79913baf8b92508cde682e508d140eeedf4b8172279a435b',
                      'b0ec5a4f7abcaa29abccfa41a86951d8c0e09d1914269e9996db1493d5aadb50',
                      'b0ec5a4f7abcaa29abccfa41a86951d8c0e09d1914269e9996db1493d5aadb50',
                      'a0ee6ce4830c234eabd6d8c47f2efca99e9b0279a13e94c98acace3c012abb2d']]],
      ['::1', ['IPv6',
               ['bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'bf935874ca13cd3c750451d0c718ffc39d459e0b49d19e1652d597d4991d8513',
                'c83803af096ec852099921237fb42957cecc27bb90d3eb76fe0af0dede9e06fb']]],
      [nil, ['', []]]
    ]
    test_data.each do |ip, expect|
      exp_family, exp_groups = expect
      act_family, act_groups = split_hash_ip(ip, users(:standard_user))
      assert_equal exp_family, act_family
      assert_equal exp_groups, act_groups
    end
  end
end
