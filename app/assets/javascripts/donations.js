$(() => {
  let elements;

  if (location.pathname.startsWith('/donate')) {
    elements = QPixel.stripe.elements();
  }

  const failValidation = (el, message) => {
    el.addClass('is-danger');
    el.parents('form').find('.js-dc-validation').text(message);
    setTimeout(() => {
      el.parents('form').find('input[type="submit"]').enable();
    }, 100);
  };

  $('.js-dc-currency').on('change', ev => {
    const symbols = {
      'GBP': '£',
      'USD': '$',
      'EUR': '€'
    };
    const selected = $(ev.target).val();
    $('.js-dc-suggestion').each((idx, el) => {
      const $el = $(el);
      $el.text(`${symbols[selected]}${$el.attr('data-amount')}`);
    });
  });

  $('.js-dc-suggestion').on('click', ev => {
    ev.preventDefault();
    const $tgt = $(ev.target);
    const amount = $tgt.attr('data-amount');
    $('.js-dc-amount').val(amount);
  });

  $('.js-dc-amount').on('change', ev => {
    const $tgt = $(ev.target);
    const amount = parseFloat($tgt.val() || '') || 1;
    const currency = $('.js-dc-currency').val();
    const formatter = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency
    });
    $tgt.val(formatter.format(amount).replaceAll(',', '').substr(1));
  });

  $('.js-dc-amt-form').on('submit', ev => {
    const $tgt = $(ev.target);
    if ($tgt.attr('data-validated') === 'true') {
      return;
    }

    const amountInput = $tgt.find('input[name="amount"]');
    const amount = amountInput.val();

    if (amount === '') {
      failValidation(amountInput, 'Please enter an amount');
      ev.preventDefault();
      return;
    }
    if (!parseFloat(amount)) {
      failValidation(amountInput, "Sorry, we can't parse that. Is there a typo somewhere?");
      ev.preventDefault();
      return;
    }
    if (parseFloat(amount) < 0.10) {
      failValidation(amountInput,
        "Sorry, we can't accept amounts under £0.10. We appreciate your generosity, but the processing fees make it prohibitive.");
      ev.preventDefault();
      return;
    }
  });

  if (location.pathname.startsWith('/donate/intent')) {
    const card = elements.create('card', {
      style: {
        base: {
          color: '#CCC',
          iconColor: '#4B68FF',

          '::placeholder': {
            color: '#BBB'
          }
        }
      }
    });
    card.mount('#stripe-df-card');

    card.on('change', ({error}) => {
      const displayError = $('#stripe-df-errors');
      if (error) {
        displayError.text(error.message);
      }
      else {
        displayError.text('');
      }
    });

    $('#stripe-df').on('submit', ev => {
      if ($(ev.target).attr('data-completed') === 'true') {
        return;
      }

      ev.preventDefault();
    }).on('submit', async (ev) => {
      const $tgt = $(ev.target);

      if ($tgt.attr('data-completed') === 'true') {
        return;
      }

      const clientSecret = $tgt.attr('data-intent');
      const billingDetails = {
        name: $tgt.find('input[name="billing_name"]').val(),
        email: $tgt.find('input[name="billing_email"]').val()
      };

      const result = await QPixel.stripe.confirmCardPayment(clientSecret, {
        payment_method: {
          card: card,
          billing_details: billingDetails
        },
        receipt_email: billingDetails.email,
        setup_future_usage: 'on_session'
      });

      if (result.error) {
        $tgt.find('#stripe-df-errors').text(result.error.message);
        setTimeout(() => {
          $tgt.find('[type="submit"]').removeAttr('disabled').text('Pay');
        }, 10);
      }
      else {
        $tgt.attr('data-completed', 'true');
        $tgt.submit();
      }
    });
  }
});