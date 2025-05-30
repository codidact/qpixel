/**
 * @typedef {{
 *  message?: string
 *  redirect_url?: string
 *  status: 'success' | 'error'
 * }} SuggestedEditActionResult
 */

$(() => {
  $('[data-suggested-edit-approve]').on('click', async (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    const editId = self.attr('data-suggested-edit-approve');
    const comment = $('#summary').val();

    const resp = await QPixel.fetchJSON(`/posts/suggested-edit/${editId}/approve`, { comment });

    /** @type {SuggestedEditActionResult} */
    const data = await resp.json();

    if (data.status !== 'success') {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + data.message);
    }
    else if (data.redirect_url) {
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

    const resp = await QPixel.fetchJSON(`/posts/suggested-edit/${editId}/reject`, { rejection_comment: comment });

    /** @type {SuggestedEditActionResult} */
    const data = await resp.json();

    if (data.status !== 'success') {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + data.message);
    }
    else if (data.redirect_url) {
      location.href = data.redirect_url;
    }
  });
});  
