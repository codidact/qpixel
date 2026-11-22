require 'test_helper'

class ZzDbScriptsInitializerTest < ActiveSupport::TestCase
  test 'should correctly preload SQL script files' do
    ['tag_children'].each do |script_name|
      cached_query = Rails.cache.persistent("#{script_name}_sql")

      loaded_query = File.read(Rails.root.join("db/scripts/#{script_name}.sql"))
      assert loaded_query.present?

      assert_equal loaded_query, cached_query
    end
  end
end
