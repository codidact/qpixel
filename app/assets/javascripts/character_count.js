$(() => {
  $('.js-character-count').each((i, el) => {
    const $el = $(el);
    const $target = $el.siblings($el.attr('data-target'));
    const max = $el.attr('data-max');

    $target.on('keyup', (ev) => {
      const $tgt = $(ev.target);
      const count = $tgt.val().length;
      const text = `${count} / ${max}`;
      if (count > max) {
        $el.removeClass('has-color-yellow-700').addClass('has-color-red-500');
        const $button = $el.parents('form').find('input[type="submit"]');
        if ($button) {
          $button.attr('disabled', true).addClass('is-muted');
        }
      }
      else if (count > 0.75 * max) {
        $el.removeClass('has-color-red-500').addClass('has-color-yellow-700');
        const $button = $el.parents('form').find('input[type="submit"]');
        if ($button) {
          $button.attr('disabled', false).removeClass('is-muted');
        }
      }
      else {
        $el.removeClass('has-color-red-500 has-color-yellow-700');
        const $button = $el.parents('form').find('input[type="submit"]');
        if ($button) {
          $button.attr('disabled', false).removeClass('is-muted');
        }
      }
      $el.text(text);
    });
  });
});