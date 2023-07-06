require 'test_helper'

class DonationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should create PaymentIntent' do
    skip if ENV['SKIP_STRIPE']
    post :intent, params: { currency: 'EUR', amount: '24.99', desc: 'Created from Rails test' }
    assert_response 200
    assert_not_nil assigns(:intent)&.id
  end
end
