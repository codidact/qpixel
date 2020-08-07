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
});