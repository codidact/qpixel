require 'test_helper'

class LicenseTest < ActiveSupport::TestCase
  test 'site_default should correctly get the default license' do
    defaults = licenses.select(&:default?)
    assert defaults.include?(License.site_default)
  end
end
