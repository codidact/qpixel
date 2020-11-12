class DonationsController < ApplicationController
  layout 'without_sidebar'

  def index; end

  def intent
    begin
      amount = params[:amount].to_f
    rescue
      flash[:danger] = 'Invalid amount. Is there a typo somewhere?'
      redirect_to donate_path
      return
    end

    if amount < 1.00
      flash[:danger] = "Sorry, we can't accept amounts below £1.00. We appreciate your generosity, but the processing "\
                       "fees make it prohibitive."
      redirect_to donate_path
      return
    end

    # amount * 100 because Stripe takes amounts in pence
    @amount = amount
    @intent = Stripe::PaymentIntent.create({ amount: (amount * 100).to_i, currency: 'GBP' },
                                           { idempotency_key: params[:authenticity_token] })
  end

  def success
    @amount = params[:amount]
    begin
      if !user_signed_in? || (user_signed_in? && !current_user.cid&.present?)
        existing = Stripe::Customer.list({ email: params[:billing_email] })[:data]
        if existing.size > 0
          @customer = existing[0]
        else
          @customer = Stripe::Customer.create({ email: params[:billing_email], name: params[:billing_name],
                                                description: current_user&.username })
        end
      else
        @customer = Stripe::Customer.retrieve(current_user.cid)
      end

      Stripe::PaymentMethod.attach(params[:pmid], { customer: @customer.id })
    rescue Stripe::StripeError => e
      ErrorLog.create(community: RequestContext.community, user: current_user, klass: e&.class,
                      message: e&.message, backtrace: e&.backtrace&.join("\n"),
                      request_uri: request.original_url, host: request.raw_host_with_port,
                      uuid: SecureRandom.uuid, user_agent: request.user_agent)
    end
    if user_signed_in?
      current_user.update(cid: @customer&.id)
    end
  end
end
