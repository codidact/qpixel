$(() => {
  $('.js-convert-to-comment, .js-toggle-comments, .js-feature-post, .js-lock').on('ajax:success', (_ev) => {
    location.reload();
  });

  $('.js-remove-promotion').on('ajax:success', (ev) => {
    const $tgt = $(ev.target);
    $tgt.parents('.widget').fadeOut(200, function () {
      $(this).remove();
    });
  });

  QPixel.DOM.addSelectorListener('click', '.flag-resolve', async (ev) => {
    ev.preventDefault();
    const tgt = /** @type {HTMLElement} */(ev.target);
    const id = tgt.dataset.flagId;

    const resolveCommentElem = tgt.parentNode?.parentNode?.querySelector('.flag-resolve-comment');

    const data = {
      result: tgt.dataset.result,
      message: resolveCommentElem instanceof HTMLTextAreaElement ? resolveCommentElem.value : ''
    };

    const req = await QPixel.jsonPost(`/mod/flags/${id}/resolve`, data);
    if (req.status === 200) {
      const res = await req.json();
      if (res.status === 'success') {
        const flagContainer = /** @type {HTMLElement} */(tgt.parentNode.parentNode.parentNode);
        QPixel.DOM.fadeOut(flagContainer, 200);
      }
      else {
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${res.message}`);
      }
    }
    else {
      QPixel.createNotification('danger', `<strong>Failed:</strong> Unexpected status (${req.status})`);
    }
  });
});
