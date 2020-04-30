$(() => {
  if (location.pathname === '/users/sign_up' || location.pathname === '/users/sign_in' && !navigator.cookieEnabled) {
    $('input[type="submit"]').attr('disabled', true).addClass('is-muted is-outlined');
    $('.js-errors').text('Cookies must be enabled in your browser for you to be able to sign up or sign in.');
  }
});