$(document).on('ready', function () {
  $('[data-suggested-edit-approve]').on('click', async (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    const editId = self.attr('data-suggested-edit-approve');

    const resp = await fetch(`/posts/suggested-edit/${editId}/approve`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      }
    });
    const data = await resp.json();

    if (data.status !== 'success') {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + data.message);
    }
    else {
      location.href = data.redirect_url;
    }
  });

  $('.js-suggested-edit-reject').on('click', (ev) => {
    ev.preventDefault();

    $(".js-suggested-edit-reject-dialog").toggleClass('is-hidden')
  });

  $('[data-suggested-edit-reject]').on('click', async (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    const editId = self.attr('data-suggested-edit-reject');
    const comment = $('.js-rejection-reason').val();

    const resp = await fetch(`/posts/suggested-edit/${editId}/reject`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      },
      body: JSON.stringify({ rejection_comment: comment })
    });
    const data = await resp.json();

    if (data.status !== 'success') {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + data.message);
    }
    else {
      location.href = data.redirect_url;
    }
  });
});  