$(() => {
  $('.js-convert-to-comment, .js-toggle-comments').on('ajax:success', ev => {
    location.reload();
  });
});