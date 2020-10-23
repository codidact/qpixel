$(() => {
  $('.js-character-count').each((i, el) => {
    const $el = $(el);
    const $target = $el.siblings($el.attr('data-target'));
    const max = $el.attr('data-max');

    $target.on('keyup cc-reset', (ev) => {
      character_count(ev);
    });

    function character_count(ev) {
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
    }

    $target.bind('paste', function(e) {
      setTimeout(function() { character_count(e); }, 100);
    });

    $target.bind('cut', function(e) {
      setTimeout(function() { character_count(e); }, 100);
    });

    $target.parents('form').on('ajax:success', ev => {
      $target.val('').trigger('cc-reset');
    });
  });
});
