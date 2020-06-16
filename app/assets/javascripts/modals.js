$(() => {
  $(document).on('click', '[data-toggle="modal"]', ev => {
    const $tgt = $(ev.target);
    const $a = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const $modal = $($a.attr('data-target'));
    $modal.toggleClass('is-active');
  });

  $(document).on('click', '.modal--header .is-close-button', ev => {
    const $tgt = $(ev.target);
    $tgt.parents('.modal').removeClass('is-active');
  });
});