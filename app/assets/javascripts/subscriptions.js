$(() => {
  $('.js-enable-subscription').on('change', async (evt) => {
    const $tgt = $(evt.target);
    const $sub = $tgt.parents('details');
    const subscriptionId = $sub.data('sub-id');
    const value = !!$tgt.is(':checked');

    const resp = await QPixel.fetchJSON(`/subscriptions/${subscriptionId}/enable`, { enabled: value }, {
      headers: { 'Accept': 'application/json' }
    });

    const data = await resp.json();

    QPixel.handleJSONResponse(data, () => {});
  });

  $('.js-remove-subscription').on('click', async (evt) => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $sub = $tgt.parents('details');
    const subscriptionId = $sub.data('sub-id');

    const resp = await QPixel.fetchJSON(`/subscriptions/${subscriptionId}`, {}, {
      headers: { 'Accept': 'application/json' },
      method: 'DELETE',
    });

    const data = await resp.json();

    QPixel.handleJSONResponse(data, () => {
      $sub.remove();
    });
  });
});
