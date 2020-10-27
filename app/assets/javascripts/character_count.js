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

    $target.on('cut paste', function(e) {
      //   This `millis` constant is not optimal, I just picked a number which is small enough for me to almost not
      // notice the timed wait (without which this change stops working!), while getting the work done. I guess this
      // hardwired timed wait might potentially not be slow enough for a browser running in a very CPU-busy client!!!
      // Here would use a media query on "system load" and choose a `millis` value safe enough so that the code in
      // `character_count` never gets run ahead of when it's supposed to.
      const millis = 100;
      setTimeout(function() { character_count(e); }, millis);
    });

    $target.parents('form').on('ajax:success', ev => {
      $target.val('').trigger('cc-reset');
    });
  });
});
