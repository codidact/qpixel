$(() => {
  $('.inbox-toggle').on('click', async evt => {
    const resp = await fetch(`/users/me/notifications`, {
      credentials: 'include',
      headers: { 'Accept': 'application/json' }
    });
    const data = await resp.json();
    const $inbox = $('.inbox');
    $inbox.html('');

    const unread = data.filter(n => !n.is_read);
    const read = data.filter(n => n.is_read);

    if (unread.length === 0) {
      $inbox.append(`<li><a href="javascript:void(0);" class="clear no-unread"><em>No unread notifications.</em></a>`)
    }
    unread.forEach(notification => {
      const item = $(`<li><a href="${notification.link}" data-id="${notification.id}" class="clear"><strong>${notification.content}</strong></a></li>"`);
      $inbox.append(item);
    });

    $inbox.append(`<li role="separator" class="divider"></li>`);
    read.forEach(notification => {
      const item = $(`<li><a href="${notification.link}" data-id="${notification.id}" class="clear read">${notification.content}</a></li>"`);
      $inbox.append(item);
    });

    $inbox.append(`<li><a href="/users/me/notifications" class="clear read"><em>See all your notifications &raquo;</em></a></li>`);
  });

  $(document).on('click', '.inbox a:not(.no-unread):not(.read)', async evt => {
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