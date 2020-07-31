$(() => {
  $('.js-convert-to-comment, .js-toggle-comments, .js-feature-post').on('ajax:success', ev => {
    location.reload();
  });
});