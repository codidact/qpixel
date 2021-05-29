$(() => {
  $('.js-convert-to-comment, .js-toggle-comments, .js-feature-post, .js-lock').on('ajax:success', ev => {
    location.reload();
  });

  $('.js-remove-promotion').on('ajax:success', ev => {
    const $tgt = $(ev.target);
    $tgt.parents('.widget').fadeOut(200, function () {
      $(this).remove();
    });
  });
});