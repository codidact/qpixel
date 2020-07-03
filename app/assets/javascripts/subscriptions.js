$(() => {
  $('.js-enable-subscription').on('change', async evt => {
    const $tgt = $(evt.target);
    const $sub = $tgt.parents('details');
    const subscriptionId = $sub.data('sub-id');
    const value = !!$tgt.is(':checked');

    const resp = await fetch(`/subscriptions/${subscriptionId}/enable`, {
      method: 'POST',
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken(), 'Content-Type': 'application/json' },
      body: JSON.stringify({enabled: value})
    });
    const data = await resp.json();

    if (data.status !== 'success') {
      QPixel.createNotification('danger', 'Failed to update your subscription. Please report this bug on Meta.');
    }
  });

  $('.js-remove-subscription').on('click', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $sub = $tgt.parents('details');
    const subscriptionId = $sub.data('sub-id');

    const resp = await fetch(`/subscriptions/${subscriptionId}`, {
      method: 'DELETE',
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
    });
    const data = await resp.json();

    if (data.status === 'success') {
      $sub.remove();
    }
    else {
      QPixel.createNotification('danger', 'Failed to remove your subscription. Please report this bug on Meta.');
    }
  });
});