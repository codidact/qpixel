document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.js-log-type-select, .js-event-type-select').forEach((el) => {
    $(el).select2();
  });
})
