$(() => {
  const setIcon = (el, icon) => {
    const icons = ['fa-ellipsis-h', 'fa-check', 'fa-exclamation-circle', 'fa-times'];
    el.removeClass(icons.join(' ')).addClass(icon);
  };

  $(document).on('keyup change paste', '[data-character-count]', ev => {
    const $tgt = $(ev.target);
    const $counter = $($tgt.attr('data-character-count'));
    const $button = $counter.parents('form').find('input[type="submit"]');
    const $count = $counter.find('.js-character-count__count');
    const $icon = $counter.find('.js-character-count__icon');

    const displayAt = parseFloat($counter.attr('data-display-at'));
    const max = parseInt($counter.attr('data-max'), 10);
    const min = parseInt($counter.attr('data-min'), 10);
    const count = $tgt.val().length;
    const text = `${count} / ${max}`;

    if (displayAt) {
      if (count >= displayAt * max) {
        $counter.removeClass('hide');
      }
      else {
        $counter.addClass('hide');
      }
    }

    if (count > max) {
      $counter.removeClass('has-color-yellow-700 has-color-primary').addClass('has-color-red-500');
      setIcon($icon, 'fa-times');
      if ($button) {
        $button.attr('disabled', true).addClass('is-muted');
      }
    }
    else if (count > 0.75 * max) {
      $counter.removeClass('has-color-red-500 has-color-primary').addClass('has-color-yellow-700');
      setIcon($icon, 'fa-exclamation-circle');
      if ($button) {
        $button.attr('disabled', false).removeClass('is-muted');
      }
    }
    else if (min && count < min) {
      $counter.removeClass('has-color-yellow-700 has-color-red-500').addClass('has-color-primary');
      setIcon($icon, 'fa-ellipsis-h');
      if ($button) {
        $button.attr('disabled', true).addClass('is-muted');
      }
      $tgt.addClass('failed-validation');
    }
    else {
      $counter.removeClass('has-color-red-500 has-color-yellow-700 has-color-primary');
      setIcon($icon, 'fa-check');
      if ($button) {
        $button.attr('disabled', false).removeClass('is-muted');
      }
      $tgt.removeClass('failed-validation');
    }

    $count.text(text);
  });

  $(document).on('ajax:success', 'form', ev => {
    const $tgt = $(ev.target);
    $tgt.find('[data-character-count]').val('').trigger('change');
  });
});
