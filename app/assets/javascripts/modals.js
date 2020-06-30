$(() => {
  $(document).on('click', '[data-modal]', ev => {
    const $tgt = $(ev.target);
    const $trigger = $tgt.is('[data-modal]') ? $tgt : $tgt.parents('[data-modal]');
    const $modal = $($trigger.attr('data-modal'));
    $modal.toggleClass('is-active');
  });

  $(document).on('keydown', ev => {
    if (ev.keyCode === 27) { // Esc
      $('.modal').removeClass('is-active');
    }
  });
});