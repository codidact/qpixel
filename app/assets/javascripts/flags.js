$(() => {
  $(document).on('click', '.flag-link', ev => {
    ev.preventDefault();
    const self = $(ev.target);
    const isCommentFlag = self.hasClass('js-comment-flag');

    let activeRadio, requiresDetails;
    let reason = -1;
    if (!isCommentFlag) {
      activeRadio = self.parents('.js-flag-box').find("input[type='radio'][name='flag-reason']:checked");
      reason = parseInt(activeRadio.val(), 10) || null;
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
    const data = {
      'flag_type': (reason !== -1) ? reason : null,
      'post_id': postId,
      'post_type': isCommentFlag ? 'Comment' : 'Post',
      'reason': $(`#flag-post-${postId}`).val()
    };

    if (requiresDetails && data['reason'].length < 15) {
      QPixel.createNotification('danger',
                                'Details are required for this flag type - please enter at least 15 characters.');
      return;
    }

    const responseType = isCommentFlag ? null : activeRadio.data('response-type');

    $.ajax({
      'type': 'POST',
      'url': '/flags/new',
      'data': data,
      'target': self
    })
      .done((response) => {
        if(response.status !== 'success') {
          QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response.message);
        }
        else {
          const messages = {
            comment: `<strong>Thanks!</strong> Your flag has been added as a comment for the author to review.`
          };
          const defaultMessage = `<strong>Thanks!</strong> A moderator will review your flag.`;
          QPixel.createNotification('success', messages[responseType] || defaultMessage);
          $(`#flag-post-${postId}`).val('');
        }
        self.parents('.js-flag-box').removeClass('is-active');
        $(`#flag-comment-${postId}`).removeClass('is-active');

      })
      .fail((jqXHR, textStatus, errorThrown) => {
        let message = jqXHR.status;
        try {
          message = JSON.parse(jqXHR.responseText)['message'];
        }
        finally {
          QPixel.createNotification('danger', '<strong>Failed:</strong> ' + message);
        }
        self.parents('.js-flag-box').removeClass('is-active');
        $(`#flag-comment-${postId}`).removeClass('is-active');
      });
  });

  $('.js-start-escalate').on('click', ev => {
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
    const resp = await fetch(`/mod/flags/${flagId}/escalate`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ comment })
    });
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
