require 'test_helper'

class EditsValidationsTest < ActiveSupport::TestCase
  def setup
    @klass = Class.new do
      include ActiveModel::Validations
      include EditsValidations

      def self.name
        'EditsValidationsTest' # otherwise, ActiveModel::Name will error out
      end

      def initialize(comment)
        super()
        @comment = comment
      end

      attr_accessor :comment
    end
  end

  test 'max_edit_comment_length should correctly validate comment length' do
    max_length = 5

    SiteSetting['MaxEditCommentLength'] = max_length

    ['a' * max_length, 'b' * (max_length + 1)].each do |comment|
      instance = @klass.new(comment)

      is_valid = instance.valid?

      if comment.length <= max_length
        assert is_valid
        assert instance.errors.none?
      else
        assert_not is_valid
        assert instance.errors[:base].any?
      end
    end
  end
end
