$(() => {
  $(document).on('click', '[data-modal]', ev => {
    const $tgt = $(ev.target);
    const $modal = $($tgt.attr('data-modal'));
    $modal.toggleClass('is-active');
  });

  $(document).on('keydown', ev => {
    if (ev.keyCode === 27) { // Esc
      $('.modal').removeClass('is-active');
    }
  });
});