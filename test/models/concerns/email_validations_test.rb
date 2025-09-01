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

  test 'blocklisted_email_domains should correctly list blocklisted email domains' do
    bad_domains = ['example.com', 'localhost']

    Tempfile.create('tmp', Rails.root.join('tmp')) do |f|
      bad_domains.each { |d| f.write("#{d}\n") }
      f.flush

      @klass.stub(:blocklisted_email_domains_path, f.path) do
        blocklisted = @klass.blocklisted_email_domains

        assert_equal bad_domains.length, blocklisted.length

        bad_domains.each do |domain|
          assert blocklisted.include?(domain)
        end
      end
    end
  end

  test 'bad_email_patterns should correctly list bad email patterns' do
    bad_patterns = ['^(.*\.)?example\.com$']

    Tempfile.create('tmp', Rails.root.join('tmp')) do |f|
      bad_patterns.each { |p| f.write("#{p}\n") }
      f.flush

      @klass.stub(:bad_email_patterns_path, f.path) do
        patterns = @klass.bad_email_patterns

        assert_equal bad_patterns.length, patterns.length

        bad_patterns.each do |pattern|
          assert patterns.include?(pattern)
        end
      end
    end
  end

  test 'email_domain_not_blocklisted should correctly determine if the domain is blocklisted' do
    instance = @klass.new('user@bad_domain.com')

    @klass.stub(:blocklisted_email_domains, ['bad_domain.com']) do
      assert_not instance.valid?
      assert instance.errors[:base].intersect?(ApplicationRecord.useful_err_msg)
      assert AuditLog.of_type('user_email_domain_blocked').exists?
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

    @klass.stub(:bad_email_patterns, ['bad_email']) do
      assert_not instance.valid?
      assert instance.errors[:base].intersect?(ApplicationRecord.useful_err_msg)
      assert @klass.new('user@example.com').valid?
    end
  end
end
