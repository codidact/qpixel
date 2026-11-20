document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.js-error-type-select').forEach((el) => {
    $(el).select2();
  });
});
