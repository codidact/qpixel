$(() => {
  const setIcon = (el, icon) => {
    const icons = ['fa-ellipsis-h', 'fa-check', 'fa-exclamation-circle', 'fa-times'];
    el.removeClass(icons.join(' ')).addClass(icon);
  };

  const setCounterState = (el, state) => {
    if(state == 'info') {
      el.removeClass('has-color-yellow-700 has-color-red-500').addClass('has-color-primary');
    } else if(state === 'warning') {
      el.removeClass('has-color-red-500 has-color-primary').addClass('has-color-yellow-700');
    } else if(state === 'error') {
      el.removeClass('has-color-yellow-700 has-color-primary').addClass('has-color-red-500');
    } else {
      el.removeClass('has-color-red-500 has-color-yellow-700 has-color-primary');
    }
  }

  const setInputState = (el, state) => {
    el.toggleClass('failed-validation', state);
  };

  const setSubmitButtonState = (el, state) => {
    if (el) {
      el.attr('disabled', state).toggleClass('is-muted', state);
    }
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
      setSubmitButtonState($button, true);
      setInputState($tgt, true);
    } else if (gteThreshold) {
      setCounterState($counter, 'warning');
      setIcon($icon, 'fa-exclamation-circle');
      setSubmitButtonState($button, false);
    } else {
      setCounterState($counter);
      setIcon($icon, 'fa-check');
      setSubmitButtonState($button, false);
      setInputState($tgt, false);
    }

    $count.text(text);
  });

  $(document).on('ajax:success', 'form', ev => {
    const $tgt = $(ev.target);
    $tgt.find('[data-character-count]').val('').trigger('change');
  });
});
