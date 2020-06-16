module ApplicationTestHelper
  def assert_array_equal(expected, object)
    [:include?, :each, :size].each do |method|
      assert expected.respond_to? method, "Expected `expected' to be array-like, got #{expected.class}"
      assert object.respond_to? method, "Expected `object' to be array-like, got #{object.class}"
    end

    assert expected.size == object.size, "Array sizes are unequal\n+++#{object}\n---#{expected}"
    expected.each do |i|
      assert object.include?(i), "Arrays are not equal: missing item #{i}\n+++#{object}\n---#{expected}"
    end
  end
end
