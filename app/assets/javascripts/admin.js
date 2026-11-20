/*!
 * FILE NOTE
 * 2024-10-12
 * Not fully converted away from jQuery yet because of rails-ujs' dependency on it.
 */

document.addEventListener('DOMContentLoaded', () => {
  $('.js-destroy-user').on('ajax:success', () => {
    location.href = '/users';
  });

  $('.js-soft-delete').on('ajax:success', (_ev, data) => {
    location.href = `/users/${data.user}`;
  }).on('ajax:error', (_ev, xhr) => {
    QPixel.createNotification('danger', xhr.responseJSON.message || 'Failed to delete.');
  });
});
