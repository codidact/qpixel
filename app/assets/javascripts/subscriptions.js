document.addEventListener('DOMContentLoaded', () => {
  /**
   * Clears subscription qualifier field value
   * @returns {void}
   */
  const clearQualifier = () => {
    const qualifierField = document.querySelector('.js-subscription-qualifier-field');

    if (qualifierField instanceof HTMLInputElement) {
      qualifierField.value = '';
    }
  };

  /**
   * Sets subscription qualifier section visibility
   * @param {boolean} visible visibility state
   * @returns {void}
   */
  const setQualifierVisibility = (visible) => {
    document.querySelector('.js-subscription-qualifier-field')
            .closest('.form-group')
            ?.classList.toggle('hide', visible);
  };

  /**
   * Is a given subscription type qualifiable?
   * @param {string} type subscription type
   * @returns {boolean}
   */
  const isQualifiable = (type) => {
    return ['category', 'tag', 'user'].includes(type);
  };

  /**
   * Is a given element a subscription type select?
   * @param {Element} element
   * @returns {element is HTMLSelectElement}
   */
  const isTypeSelect = (element) => {
    return element.matches('.js-subscription-type-select');
  };

  document.querySelectorAll('.js-subscription-type-select, .js-subscription-frequency-select').forEach((el) => {
    $(el).select2().on('change', ($event) => {
      if (isTypeSelect($event.target)) {
        clearQualifier();
        setQualifierVisibility(!isQualifiable($event.target.value));
      }
    });
  });

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
