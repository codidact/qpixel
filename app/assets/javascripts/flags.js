$(() => {
  $(document).on('click', '.flag-link', async (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    const isCommentFlag = self.hasClass('js-comment-flag');

    let activeRadio, requiresDetails;
    let reason = -1;
    if (!isCommentFlag) {
      activeRadio = self.parents('.js-flag-box').find("input[type='radio'][name='flag-reason']:checked");
      reason = parseInt(activeRadio.val()?.toString(), 10) || null;
      requiresDetails = activeRadio.attr('data-requires-details') === 'true';

      if (reason === null) {
        QPixel.createNotification('danger', 'Please choose a reason.');
        return;
      }
    }
    else {
      requiresDetails = self.attr('data-requires-details') === 'true';
    }

    const postId = self.data('post-id');

    /**
     * @type {QPixelFlagData}
     */
    const data = {
      'flag_type': (reason !== -1) ? reason : null,
      'post_id': postId,
      'post_type': isCommentFlag ? 'Comment' : 'Post',
      'reason': $(`#flag-post-${postId}`).val()?.toString()
    };

    if (requiresDetails && data['reason'].length < 1) {
      QPixel.createNotification('danger', 'Details are required for this flag type - please enter a message.');
      return;
    }

    const closeFlagModal = () => {
      self.parents('.js-flag-box').removeClass('is-active');
      $(`#flag-comment-${postId}`).removeClass('is-active');
    };

    try {
      const response = await QPixel.flag(data);

      QPixel.handleJSONResponse(response, (data) => {
        QPixel.createNotification('success', data.message);
        $(`#flag-post-${postId}`).val('');
      }, closeFlagModal);
    } catch(e) {
      console.warn(`[flags/new] API error:`, e);
      QPixel.createNotification('danger', 'Failed to flag.');
    }
  });

  QPixel.DOM?.watchClass('.js-flag-box.is-active', (target) => {
    const reasonInput = target.querySelector('input[name="flag-reason"]');

    if (QPixel.DOM?.isHTMLElement(reasonInput)) {
      reasonInput.focus();
    }
  });

  QPixel.DOM?.watchClass('[id^="flag-comment"].is-active', (target) => {
    const reasonInput = target.querySelector('.js-comment-flag-reason');

    if (QPixel.DOM?.isHTMLElement(reasonInput)) {
      reasonInput.focus();
    }
  });

  $('.js-start-escalate').on('click', (ev) => {
    const $modal = $('.js-escalation-modal');
    const $tgt = $(ev.target);
    const flagId = $tgt.data('flag');
    $modal.data('flag', flagId);
    $modal.toggleClass('is-active');
  });

  $('.js-flag-escalate').on('click', async () => {
    const $modal = $('.js-escalation-modal');
    const $comment = $('.js-escalation-comment');
    const flagId = $modal.data('flag');
    const comment = $comment.val();

    const resp = await QPixel.fetchJSON(`/mod/flags/${flagId}/escalate`, { comment });

    if (resp.status === 200) {
      QPixel.createNotification('success', 'This flag has been escalated for admin review.');
      $modal.toggleClass('is-active');
      $comment.val('');
    }
    else {
      QPixel.createNotification('danger', 'Failed to escalate flag.');
    }
  });
});
