$(() => {
  $('.js-close-question').on('click', (ev) => {
    ev.preventDefault();

    const self = $(ev.target);
    const activeRadio = self.parents('.js-close-box').find("input[type='radio'][name='close-reason']:checked");
    const otherPostInput = activeRadio.parents('.widget--body').find('.js-close-other-post');
    const otherPostRequired = activeRadio.attr('data-rop') === 'true';
    const data = {
      'reason_id': activeRadio.val(),
      'other_post': otherPostInput.val()
      // option will be silently discarded if no input element
    };

    if (data['other_post']) {
      if (data['other_post'].match(/\/[0-9]+$/)) {
        data['other_post'] = data['other_post'].replace(/.*\/([0-9]+)$/, "$1");
      }
    }

    if (!activeRadio.val()) {
      QPixel.createNotification('danger', 'You must select a close reason.');
      return;
    }
    if (!otherPostInput.val() && otherPostRequired) {
      QPixel.createNotification('danger', 'You must enter an ID or URL to another post.');
      return;
    }

    $.ajax({
      'type': 'POST',
      'url': '/posts/' + self.data('post-id') + '/close',
      'data': data,
      'target': self
    })
    .done((response) => {
      if(response.status !== 'success') {
        QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response.message);
      }
      else {
        location.reload();
      }
    })
    .fail((jqXHR, textStatus, errorThrown) => {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + jqXHR.status);
      console.log(jqXHR.responseText);
    });
  });
});
