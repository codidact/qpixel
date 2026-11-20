require 'test_helper'

class PostCreationValidationsTest < ActiveSupport::TestCase
  def setup
    @klass = Class.new do
      include ActiveModel::Validations
      include ActiveRecord::Callbacks
      include PostCreationValidations

      def self.name
        'PostCreationValidationsTest' # otherwise, ActiveModel::Name will error out
      end

      def initialize(category:, post_type:, title:, user:)
        super()
        @category = category
        @post_type = post_type
        @title = title
        @user = user
      end

      attr_accessor :category
      attr_accessor :post_type
      attr_accessor :title
      attr_accessor :user

      def title?
        title.present?
      end
    end
  end

  test ':no_mathjax_in_title should correctly check for MathJax in titles' do
    category = categories(:main)
    post_type = post_types(:question)
    user = users(:standard_user)

    expected = [
      ['this is a valid title', true],
      ['this $$ is invalid in a title', false, 'no_block_mathjax_title']
    ]

    expected.each do |test_case|
      instance = @klass.new(category: category,
                            post_type: post_type,
                            title: test_case.first,
                            user: user)

      is_valid = instance.valid?(:create)

      assert_equal test_case.second, is_valid

      next if is_valid

      assert instance.errors[:base].include?(
        I18n.t("posts.#{test_case.third}")
      )
    end
  end
end
