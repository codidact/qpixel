$(() => {
  if ((location.pathname === '/users/sign_up' || location.pathname === '/users/sign_in') && !navigator.cookieEnabled) {
    $('input[type="submit"]').attr('disabled', true).addClass('is-muted is-outlined');
    $('.js-errors').text('Cookies must be enabled in your browser for you to be able to sign up or sign in.');
  }

  $('.js-role-grant-btn').on('click', async ev => {
    const $tgt = $(ev.target);
    const resp = await fetch(`/users/${$tgt.attr('data-user')}/mod/toggle-role`, {
      method: 'POST',
      body: JSON.stringify({ role: $tgt.attr('data-role') }),
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      credentials: 'include'
    });
    const data = await resp.json();
    if (resp.status !== 200 || data.status !== 'success') {
      QPixel.createNotification('danger', `<strong>Failed:</strong> ${data.message}`);
    }
    else {
      location.reload();
    }
  });

  $('.js-ability-grant-btn').on('click', async ev => {
    const $tgt = $(ev.target);
    const resp = await fetch(`/users/${$tgt.attr('data-user')}/mod/privileges`, {
      method: 'POST',
      body: JSON.stringify({ do: 'grant', ability: $tgt.attr('data-ability') }),
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      credentials: 'include'
    });
    const data = await resp.json();
    if (resp.status !== 200 || data.status !== 'success') {
      QPixel.createNotification('danger', `<strong>Failed:</strong> ${data.message}`);
    }
    else {
      location.reload();
    }
  });

  $('.js-ability-delete-btn').on('click', async ev => {
    if (!confirm('Delete this ability?\n\nThis will remove the ability but it will come back when the abilities are recalculated,\nas long as the requirements are still met.\n\nYou\'ll probably want to use ability suspensions instead.')) return;
    const $tgt = $(ev.target);
    const resp = await fetch(`/users/${$tgt.attr('data-user')}/mod/privileges`, {
      method: 'POST',
      body: JSON.stringify({ do: 'delete', ability: $tgt.attr('data-ability') }),
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      credentials: 'include'
    });
    const data = await resp.json();
    if (resp.status !== 200 || data.status !== 'success') {
      QPixel.createNotification('danger', `<strong>Failed:</strong> ${data.message}`);
    }
    else {
      location.reload();
    }
  });

  $('.js-ability-suspend-btn').on('click', async ev => {
    const $tgt = $(ev.target);
    const ability = $tgt.attr('data-ability');
    const resp = await fetch(`/users/${$tgt.attr('data-user')}/mod/privileges`, {
      method: 'POST',
      body: JSON.stringify({
        do: 'suspend',
        ability,
        duration: $("#suspend-ability-" + ability + "-duration").val(),
        message: $("#suspend-ability-" + ability + "-message").val()
      }),
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      credentials: 'include'
    });
    const data = await resp.json();
    if (resp.status !== 200 || data.status !== 'success') {
      QPixel.createNotification('danger', `<strong>Failed:</strong> ${data.message}`);
    }
    else {
      location.reload();
    }
  });
});