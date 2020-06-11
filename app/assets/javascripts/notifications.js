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
      const $inboxContainer = $inbox.find(".inbox--container");
      $inboxContainer.html('');
  
      const unread = data.filter(n => !n.is_read);
      const read = data.filter(n => n.is_read);

      console.log(read);
  
      unread.forEach(notification => {
        const item = $(`<div class="widget is-teal h-m-0 h-m-b-2"><div class="widget--body h-p-2"><div class="h-c-tertiary-600 h-fs-caption">${notification.community_name} &middot; <strong>unread</strong></div><a href="${notification.link}" data-id="${notification.id}" class="h-fw-bold is-not-underlined">${notification.content}</a></div></div>`);
        $inboxContainer.append(item);
      });
  
      $inboxContainer.append(`<div role="separator" class="header-slide--separator"></div>`);
      read.forEach(notification => {
        const item = $(`<div class="widget h-m-0 h-m-b-2"><div class="widget--body h-p-2"><div class="h-c-tertiary-600 h-fs-caption">${notification.community_name} &middot; read</div><a href="${notification.link}" data-id="${notification.id}" class="h-fw-bold is-not-underlined">${notification.content}</a></div></div>"`);
        $inboxContainer.append(item);
      });
  
      $inboxContainer.append(`<a href="/users/me/notifications" class="button is-muted is-small">See all your notifications &raquo;</a>`);
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

  const headerSlideTriggers = $("[data-trigger-header-slide]");

  headerSlideTriggers.on("click", function (e) {
    $this = $(this);
    const headerSlide = $($this.attr("data-trigger-header-slide"));

    headerSlide.toggleClass("is-active");
    $this.toggleClass("is-active");

    // Position header slide appropriately relative to
    // trigger.
    const rect = $this[0].getBoundingClientRect();
    hs.css({
      "top": (rect.top + rect.height) + "px",
      "right": (document.body.clientWidth - rect.right) + "px"
    });

    // Prevent navigation
    e.preventDefault();
  });

});