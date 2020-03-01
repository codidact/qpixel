$(() => {
  $('.inbox-toggle').on('click', async evt => {
    evt.preventDefault();
    const $inbox = $('.inbox');
    $inbox.toggleClass("is-active");

    const rect = $(".inbox-toggle").toggleClass("is-active")[0].getBoundingClientRect();
    $inbox.css({
      top: (rect.top + rect.height) + "px",
      right: (document.body.clientWidth - rect.right) + "px"
    });

    if($inbox.hasClass("is-active")) {
      const resp = await fetch(`/users/me/notifications`, {
        credentials: 'include',
        headers: { 'Accept': 'application/json' }
      });
      const data = await resp.json();
      $inbox.html('');
  
      const unread = data.filter(n => !n.is_read);
      const read = data.filter(n => n.is_read);
  
      if (unread.length === 0) {
        $inbox.append(`<div class="has-padding-2 has-margin-left-2 has-margin-right-2"><em>No unread notifications</em></div>`)
      }
      unread.forEach(notification => {
        const item = $(`<a href="${notification.link}" data-id="${notification.id}" class="header-slide--item"><span class="header-slide--alert">unread</span>${notification.content}</a>"`);
        $inbox.append(item);
      });
  
      $inbox.append(`<div role="separator" class="header-slide--separator"></div>`);
      read.forEach(notification => {
        const item = $(`<a href="${notification.link}" data-id="${notification.id}" class="header-slide--item has-font-weight-normal">${notification.content}</a>"`);
        $inbox.append(item);
      });
  
      $inbox.append(`<a href="/users/me/notifications" class="header-slide--item has-font-weight-normal"><em>See all your notifications &raquo;</em></a>`);
   } else {
      await fetch(`/notifications/read_all`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
      });
      const $inboxCount = $('.inbox-count');
      $inboxCount.text('');
    }
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

});
