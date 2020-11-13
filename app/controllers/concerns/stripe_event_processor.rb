class StripeEventProcessor
  def self.payment_intent_succeeded(object, event)
    id_key = event[:id]

    method_id = object[:payment_method]
    method = Stripe::PaymentMethod.retrieve(method_id)
    billing_details = method[:billing_details]

    user = if object[:metadata][:user_id].present?
             User.find(object[:metadata][:user_id])
           end

    customer = if user.present? && user.cid.present?
                 begin
                   Stripe::Customer.retrieve(user.cid)
                 rescue Stripe::InvalidRequestError
                   Stripe::Customer.create({ name: billing_details[:name], email: billing_details[:email],
                                             description: user.present? ? user.username : 'anonymous donor' },
                                           { idempotency_key: id_key })
                 end
               else
                 existing = Stripe::Customer.list({ email: billing_details[:email] })[:data]
                 if !existing.empty?
                   existing[0]
                 else
                   Stripe::Customer.create({ name: billing_details[:name], email: billing_details[:email],
                                             description: user.present? ? user.username : 'anonymous donor' },
                                           { idempotency_key: id_key })
                 end
               end

    if user.present? && user.cid != customer.id
      user.update(cid: customer.id)
    end

    cust_methods = Stripe::PaymentMethod.list({ customer: customer.id, type: 'card' })[:data]

    if method.customer.present?
      method.detach
    end

    if !cust_methods.empty? && cust_methods.any? { |pm| pm[:card][:fingerprint] == method[:card][:fingerprint] }
      "Already attached (#{method[:card][:fingerprint]})."
    elsif object[:setup_future_usage].present?
      method.attach({ customer: customer.id })
      'Attached.'
    else
      'Future not set up, unable to attach.'
    end
  end
end
