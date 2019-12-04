$(() => {
  $('.inbox-toggle').on('click', async evt => {
    const resp = await fetch(`/users/me/notifications`, {
      credentials: 'include',
      headers: { 'Accept': 'application/json' }
    });
    const data = await resp.json();
    const $inbox = $('.inbox');
    $inbox.html('');
    data.forEach(notification => {
      const item = $(`<li><a href="${notification.link}" data-id="${notification.id}" class="clear">${notification.content}</a></li>"`);
      $inbox.append(item);
    });
  });

  $(document).on('click', '.inbox a', async evt => {
    const $tgt = $(evt.target);
    const id = $tgt.data('id');
    await fetch(`/notifications/${id}/read`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
    });
    const $inboxCount = $('.inbox-count');
    const currentCount = parseInt($inboxCount.text(), 10);
    $inboxCount.text(currentCount - 1);
  });

  $(document).on('hide.bs.dropdown', async evt => {
    const $tgt = $(evt.relatedTarget);
    if ($tgt.hasClass('inbox-toggle')) {
      await fetch(`/notifications/read_all`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
      });
      const $inboxCount = $('.inbox-count');
      $inboxCount.text('');
    }
  });
});