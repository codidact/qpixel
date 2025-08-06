document.addEventListener('DOMContentLoaded', () => {
  /**
   * Extracts qualifier type from the field's dataset
   * @returns {string | null}
   */
  const getQualifierType = () => {
    const field = document.querySelector('.js-sub-type-select');
    return field instanceof HTMLSelectElement ? field.value : null;
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
   * Synchronizes qualifier field with the given type
   * @param {string} type subscription type
   */
  const syncQualifier = (type) => {
    const field = document.querySelector('.js-sub-qualifier-select');

    if (field instanceof HTMLElement) {
      $(field).val(null).trigger('change');
      field.closest('.form-group')?.classList.toggle('hide', !isQualifiable(type));
    }
  };

  /**
   * Is a given element a subscription type select?
   * @param {Element} element
   * @returns {element is HTMLSelectElement}
   */
  const isTypeSelect = (element) => {
    return element.matches('.js-sub-type-select');
  };

  document.querySelectorAll('.js-sub-type-select, .js-sub-frequency-select').forEach((el) => {
    $(el).select2().on('change', ($event) => {
      if (isTypeSelect($event.target)) {
        syncQualifier($event.target.value);
      }
    });
  });

  $('.js-sub-qualifier-select').select2({
    ajax: {
      url: () => {
        const type = getQualifierType();
        return `/subscriptions/qualifiers?type=${type}`
      },
      headers: { 'Accept': 'application/json' },
      delay: 100,
      processResults: (results) => {
        return { results }
      },
    }
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
