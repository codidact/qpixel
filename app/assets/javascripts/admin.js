$(() => {
  $('.js-destroy-user, .js-soft-delete').on('ajax:success', () => {
    location.href = '/users';
  });
});