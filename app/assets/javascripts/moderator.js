$(() => {
  $('.js-convert-to-comment, .js-toggle-comments, .js-feature-post, .js-lock').on('ajax:success', ev => {
    location.reload();
  });
});