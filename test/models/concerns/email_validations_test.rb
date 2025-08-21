require 'test_helper'

class EmailValidationsTest < ActiveSupport::TestCase
  def setup
    @klass = Class.new do
      include ActiveModel::Validations
      include EmailValidations

      def self.name
        'EmailValidationsTest' # otherwise, ActiveModel::Name will error out
      end

      def initialize(email)
        super()
        @email = email
      end

      def changes = ['email']
      def saved_changes = ['email']

      attr_accessor :email
    end
  end

  test 'email_domain_not_blocklisted should correctly determine if the domain is blocklisted' do
    instance = @klass.new('user@bad_domain.com')

    instance.stub(:blocklisted_email_domains, ['bad_domain.com']) do
      assert_not instance.valid?
      assert instance.errors[:base].intersect?(ApplicationRecord.useful_err_msg)
      assert @klass.new('user@example.com')
    end
  end

  test 'email_not_blocklisted should correctly determine if the email is blocklisted' do
    instance = @klass.new(blocked_items(:email).value)

    assert_not instance.valid?
    assert instance.errors[:base].intersect?(ApplicationRecord.useful_err_msg)
    assert @klass.new('user@example.com').valid?
  end

  test 'email_not_bad_pattern should correctly determine if the email contains bad patterns' do
    instance = @klass.new('bad_email@example.com')

    instance.stub(:bad_email_patterns, ['bad_email']) do
      assert_not instance.valid?
      assert instance.errors[:base].intersect?(ApplicationRecord.useful_err_msg)
      assert @klass.new('user@example.com').valid?
    end
  end
end
