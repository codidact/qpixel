$(() => {
  $('.js-destroy-user').on('ajax:success', () => {
    location.href = '/users';
  });

  $('.js-soft-delete').on('ajax:success', (_ev, data) => {
    location.href = `/users/${data.user}`;
  }).on('ajax:error', (_ev, xhr) => {
    QPixel.createNotification('danger', xhr.responseJSON.message || 'Failed to delete.');
  });
});