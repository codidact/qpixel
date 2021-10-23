$(() => {
  const makeNotification = notification => {
    const template = `<div class="js-notification widget h-m-0 h-m-b-2 ${notification.is_read ? 'read' : 'is-teal'}">
        <div class="widget--body h-p-2">
            <div class="h-c-tertiary-600 h-fs-caption">
                ${notification.community_name} &middot;
                <span class="js-notif-state">${notification.is_read ? 'read' : `<strong>unread</strong>`}</span> &middot;
                <span data-livestamp="${notification.created_at}">${notification.created_at}</span>
            </div>
            <p><a href="${notification.link}" data-id="${notification.id}"
                  class="h-fw-bold is-not-underlined ${notification.is_read ? 'read' : ''}">${notification.content}</a></p>
            <p class="has-font-size-caption"><a href="javascript:void(0)" data-notif-id="${notification.id}" class="js-notification-toggle">
                <i class="fas fa-${notification.is_read ? 'envelope' : 'envelope-open'}"></i>
                mark ${notification.is_read ? 'unread' : 'read'}
            </a></p>
        </div>
    </div>`;
    return template;
  };

  const changeInboxCount = change => {
    const counter = $('.inbox-count');
    let count;
    if (counter.length !== 0) {
      count = parseInt(counter.text(), 10);
    }
    else {
      count = 0;
    }
    count = Math.max(0, count + change);

    if (count === 0 && counter.length !== 0) {
      counter.remove();
    }
    else {
      if (counter.length === 0) {
        $(`<span class="header--alert inbox-count">${count}</span>`).prependTo($('.inbox-toggle'));
      }
      else {
        counter.text(count);
      }
    }
  };

  $('.inbox-toggle').on('click', async evt => {
    evt.preventDefault();
    const $inbox = $('.inbox');
    if($inbox.hasClass("is-active")) {
      const resp = await fetch(`/users/me/notifications`, {
        credentials: 'include',
        headers: { 'Accept': 'application/json' }
      });
      const data = await resp.json();
      const $inboxContainer = $inbox.find(".inbox--container");
      $inboxContainer.html('');
  
      const unread = data.filter(n => !n.is_read);
      const read = data.filter(n => n.is_read);
  
      unread.forEach(notification => {
        const item = $(makeNotification(notification));
        $inboxContainer.append(item);
      });
  
      $inboxContainer.append(`<div role="separator" class="header-slide--separator"></div>`);
      read.forEach(notification => {
        const item = $(makeNotification(notification));
        $inboxContainer.append(item);
      });
  
      $inboxContainer.append(`<a href="/users/me/notifications" class="button is-muted is-small">See all your notifications &raquo;</a>`);
    }
  });

  $('.js-read-all-notifs').on('click', async ev => {
    ev.preventDefault();

    await fetch(`/notifications/read_all`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
    });

    $('.inbox-count').remove();

    $('.js-notification').removeClass('is-teal').addClass('read');
    $('.js-notif-state').text('read');
    $('.js-notification-toggle').html(`<i class="fas fa-envelope"></i> mark unread`);
  });

  $(document).on('click', '.inbox a:not(.no-unread):not(.read):not(.js-notification-toggle)', async evt => {
    const $tgt = $(evt.target);
    const id = $tgt.data('id');
    const resp = await fetch(`/notifications/${id}/read`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
    });
    const data = await resp.json();
    $tgt.parents('.js-notification')[0].outerHTML = makeNotification(data.notification);
    changeInboxCount(-1);
  });

  $(document).on('click', '.js-notification-toggle', async ev => {
    ev.stopPropagation();

    const $tgt = $(ev.target).is('a') ? $(ev.target) : $(ev.target).parents('a');
    const id = $tgt.attr('data-notif-id');
    const resp = await fetch(`/notifications/${id}/read`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() }
    });
    const data = await resp.json();
    if (data.status !== 'success') {
      console.error('Failed to toggle notification read state. Wat?');
      return;
    }

    $tgt.parents('.js-notification')[0].outerHTML = makeNotification(data.notification);

    const change = data.notification.is_read ? -1 : +1;
    changeInboxCount(change);
  });
});