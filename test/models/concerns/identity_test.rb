require 'test_helper'

class IdentityTest < ActiveSupport::TestCase
  def setup
    @klass1 = Class.new do
      include Identity

      def initialize(id)
        super()
        @id = id
      end
      attr_accessor :id
    end

    @klass2 = Class.new do
      include Identity

      def initialize(id)
        super()
        @id = id
      end
      attr_accessor :id
    end
  end

  test 'same_as? should correctly determine identity' do
    first = @klass1.new(42)
    second = @klass1.new(42)
    third = @klass1.new(777)

    assert first.same_as?(second)
    assert_not first.same_as?(third)
  end

  test 'same_as? should ensure compared models are the same' do
    first = @klass1.new(42)
    second = @klass2.new(42)

    assert_not first.same_as?(second)
  end

  test 'same_as? should not fail if the compared model is nil' do
    first = @klass1.new(42)

    assert_nothing_raised do
      first.same_as?(nil)
    end

    assert_not first.same_as?(nil)
  end
end
