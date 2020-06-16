$(() => {
  $('.js-convert-to-comment').on('ajax:success', ev => {
    location.reload();
  });
});