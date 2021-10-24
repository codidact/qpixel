class DonationsController < ApplicationController
  layout 'stripe'
  skip_forgery_protection only: [:callback]
  skip_before_action :set_globals, only: [:callback]
  skip_before_action :check_if_warning_or_suspension_pending, only: [:callback]
  skip_before_action :stop_the_awful_troll, only: [:callback]
  skip_before_action :distinguish_fake_community, only: [:callback]

  def index; end

  def intent
    @referrer = params[:return_to]
    currencies = ['GBP', 'USD', 'EUR']
    @currency = currencies.include?(params[:currency]) ? params[:currency] : 'GBP'
    @symbol = { 'GBP' => '£', 'USD' => '$', 'EUR' => '€' }[@currency]
    begin
      amount = params[:amount].to_f
    rescue
      flash[:danger] = 'Invalid amount. Is there a typo somewhere?'
      redirect_to donate_path
      return
    end

    if amount < 0.10
      flash[:danger] = "Sorry, we can't accept amounts below #{symbol}0.10. We appreciate your generosity, but the " \
                       'processing fees make it prohibitive.'
      redirect_to donate_path
      return
    end

    # amount * 100 because Stripe takes amounts in pence
    @amount = amount
    @intent = Stripe::PaymentIntent.create({ amount: (amount * 100).to_i, currency: @currency,
                                             metadata: { user_id: current_user&.id } },
                                           { idempotency_key: params[:authenticity_token] })
  end

  def success
    @amount = params[:amount]
    @symbol = params[:currency]
    @referrer = params[:return_to]
  end

  def callback
    secret = Rails.application.credentials.stripe_webhook_secret
    payload = request.body.read
    signature = request.headers['Stripe-Signature']

    begin
      event = Stripe::Webhook.construct_event(payload, signature, secret)
    rescue JSON::ParserError
      respond_to do |format|
        format.json do
          render status: 400, json: { error: 'Check yo JSON syntax. Fam.' }
        end
        format.any do
          render status: 400, plain: 'Check yo JSON syntax. Fam.'
        end
      end
      return
    rescue Stripe::SignatureVerificationError
      respond_to do |format|
        format.json do
          render status: 400, json: { error: "You're not Stripe. Go away." }
        end
        format.any do
          render status: 400, plain: "You're not Stripe. Go away."
        end
      end
      return
    end

    if event.nil?
      respond_to do |format|
        format.json do
          render status: 500, json: { error: 'Webhook event not created. ???' }
        end
        format.any do
          render status: 500, plain: 'Webhook event not created. ???'
        end
      end
      return
    end

    object = event.data.object
    method = event.type.gsub('.', '_')
    if StripeEventProcessor.respond_to?(method)
      begin
        result = StripeEventProcessor.send(method, object, event)
        render status: 200, json: { status: 'Accepted for processing.', result: result }
      rescue Stripe::StripeError => e
        error_id = SecureRandom.uuid
        ErrorLog.create(community: RequestContext.community, user: current_user, klass: e&.class,
                        message: e&.message, backtrace: e&.backtrace&.join("\n"), request_uri: request.original_url,
                        host: request.raw_host_with_port, uuid: error_id, user_agent: request.user_agent)
        render status: 500, json: { error: "#{e&.class}: #{error_id} created." }
      end
    else
      render status: 202, json: { status: 'Accepted, not processed.' }
    end
  end
end
