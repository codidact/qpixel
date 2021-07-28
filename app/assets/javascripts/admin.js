$(() => {
  $('.js-destroy-user').on('ajax:success', () => {
    location.href = '/users';
  });

  $('.js-soft-delete').on('ajax:success', (ev, data) => {
    location.href = `/users/${data.user}`;
  });
});