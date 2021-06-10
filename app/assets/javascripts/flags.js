$(() => {
  $('.flag-link').on('click', ev => {
    ev.preventDefault();
    const self = $(ev.target);

    const activeRadio = self.parents(".js-flag-box").find("input[type='radio'][name='flag-reason']:checked");
    const reason = parseInt(activeRadio.val(), 10) || null;

    if (reason === null) {
      QPixel.createNotification('danger', "Please choose a reason.");
      return;
    }

    const data = {
      'flag_type': (reason !== -1) ? reason : null,
      'post_id': self.data("post-id"),
      'reason': self.parents(".js-flag-box").find(".js-flag-comment").val()
    };

    if (activeRadio.attr('data-requires-details') === 'true' && data['reason'].length < 15) {
      QPixel.createNotification('danger',
                                'Details are required for this flag type - please enter at least 15 characters.');
      return;
    }

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
          QPixel.createNotification('success', '<strong>Thanks!</strong> A moderator will review your flag.');
          self.parents(".js-flag-box").find(".js-flag-comment").val("");
        }
        self.parents(".js-flag-box").removeClass("is-active");
      })
      .fail((jqXHR, textStatus, errorThrown) => {
        let message = jqXHR.status;
        try {
          message = JSON.parse(jqXHR.responseText)['message'];
        }
        finally {
          QPixel.createNotification('danger', '<strong>Failed:</strong> ' + message);
        }
        self.parents(".js-flag-box").removeClass("is-active");
      });
  });
});
