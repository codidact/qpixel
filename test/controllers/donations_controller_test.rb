require 'test_helper'

class DonationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    WebMock.allow_net_connect!
  end

  teardown do
    WebMock.disable_net_connect!
  end

  test 'should get index' do
    get :index
    assert_response(:success)
  end

  test ':intent should safely handle referrer URIs' do
    Stripe::PaymentIntent.stub(:create, nil) do
      referrer_test_cases.each do |test_case|
        get :intent, params: { return_to: test_case.first }
        assert_equal test_case.second, assigns(:referrer).present?
      end
    end
  end

  test ':success should safely handle referrer URIs' do
    Stripe::PaymentIntent.stub(:update, true) do
      referrer_test_cases.each do |test_case|
        get :success, params: {
          billing_email: 'donator@example.com',
          billing_name: 'donations_tester',
          return_to: test_case.first
        }
        assert_equal test_case.second, assigns(:referrer).present?
      end
    end
  end

  test ':intent should correctly create PaymentIntent' do
    skip unless Stripe.api_key
    post :intent, params: { currency: 'EUR', amount: '24.99', desc: 'Created from Rails test' }

    assert_response(:success)
    assert_not_nil assigns(:intent)&.id
  end

  test ':callback should correctly handle missing events' do
    Stripe::Webhook.stub(:construct_event, nil) do
      post :callback, params: { format: :json }

      assert_response(:internal_server_error)
      assert_nothing_raised do
        parsed = JSON.parse(response.body)
        assert_not_nil(parsed)
        assert_equal 'Webhook event not created.', parsed['error']
      end
    end
  end

  private

  def referrer_test_cases
    [
      ['http://example.com/qa', true],
      ['https://example.com/qa', true],
      ['/relative_path', true],
      ["javascript:alert('oops!')", false],
      ['ftp://example.com/donwload', false]
    ]
  end
end
