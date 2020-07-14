$(() => {
  $(document).on('keydown', ev => {
    if (ev.keyCode === 27) { // Esc
      $('.modal').removeClass('is-active');
    }
  });
});