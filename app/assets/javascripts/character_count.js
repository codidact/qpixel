$(() => {
  $('.js-character-count').each((i, el) => {
    const $el = $(el);
    const $target = $el.siblings($el.attr('data-target'));
    const max = $el.attr('data-max');

    $target.on('keyup', (ev) => {
      const $tgt = $(ev.target);
      const count = $tgt.val().length;
      const text = `${count} / ${max}`;
      if (count >= max) {
        $el.addClass('has-color-red-500');
        const $button = $el.parents('form').find('input[type="submit"]');
        if ($button) {
          $button.attr('disabled', true).addClass('is-muted');
        }
      }
      else {
        $el.removeClass('has-color-red-500');
        const $button = $el.parents('form').find('input[type="submit"]');
        if ($button) {
          $button.attr('disabled', false).removeClass('is-muted');
        }
      }
      $el.text(text);
    });
  });
});