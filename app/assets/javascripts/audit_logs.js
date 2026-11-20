document.addEventListener('DOMContentLoaded', () => {
  document
    .querySelectorAll(['.js-log-type-select', '.js-event-type-select', '.js-community-select'].join(', '))
    .forEach((el) => {
      $(el).select2();
    });
});
