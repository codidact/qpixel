$(() => {
  const setIcon = (el, icon) => {
    const icons = ['fa-ellipsis-h', 'fa-check', 'fa-exclamation-circle', 'fa-times'];
    el.removeClass(icons.join(' ')).addClass(icon);
  };

  /**
   * Sets the counter's state
   * @param {'info'|'warning'|'error'|'default'} state 
   */
  const setCounterState = (el, state) => {
    if(state === 'info') {
      el.removeClass('has-color-yellow-700 has-color-red-500').addClass('has-color-primary');
    }
    else if(state === 'warning') {
      el.removeClass('has-color-red-500 has-color-primary').addClass('has-color-yellow-700');
    }
    else if(state === 'error') {
      el.removeClass('has-color-yellow-700 has-color-primary').addClass('has-color-red-500');
    }
    else {
      el.removeClass('has-color-red-500 has-color-yellow-700 has-color-primary');
    }
  }

  /**
   * Sets the input's validation state
   * @param {'valid'|'invalid'} state the state to set
   */
  const setInputValidationState = (el, state) => {
    const isInvalid = state === 'invalid';
    el.toggleClass('failed-validation', isInvalid);
  };

  /**
   * Sets the submit button's disabled state
   * @param {'disabled'|'enabled'} state the state to set
   */
  const setSubmitButtonDisabledState = (el, state) => {
    const isDisabled = state === 'disabled';
    el.attr('disabled', isDisabled).toggleClass('is-muted', isDisabled);
  };

  $(document).on('keyup change paste', '[data-character-count]', (ev) => {
    const $tgt = $(ev.target);
    const $counter = $($tgt.attr('data-character-count'));
    const $button = $counter.parents('form').find('input[type="submit"]');
    const $count = $counter.find('.js-character-count__count');
    const $icon = $counter.find('.js-character-count__icon');

    const count = $tgt.val().length;
    const max = parseInt($counter.attr('data-max'), 10);
    const min = parseInt($counter.attr('data-min'), 10);
    const threshold = parseFloat($counter.attr('data-threshold'));

    const gtnMax = count > max;
    const ltnMin = count < min;
    const gteThreshold = count >= threshold * max;

    const text = `${count} / ${ltnMin ? min : max}`;
    
    if(gtnMax || ltnMin) {
      setCounterState($counter, 'error');
      setIcon($icon, 'fa-times');
      setSubmitButtonDisabledState($button, 'disabled');
      setInputValidationState($tgt, 'invalid');
    } else if (gteThreshold) {
      setCounterState($counter, 'warning');
      setIcon($icon, 'fa-exclamation-circle');
      setSubmitButtonDisabledState($button, 'enabled');
    } else {
      setCounterState($counter, 'default');
      setIcon($icon, 'fa-check');
      setSubmitButtonDisabledState($button, 'enabled');
      setInputValidationState($tgt, 'valid');
    }

    $count.text(text);
  });

  $(document).on('ajax:success', 'form', ev => {
    const $tgt = $(ev.target);
    $tgt.find('[data-character-count]').val('').trigger('change');
  });
});
