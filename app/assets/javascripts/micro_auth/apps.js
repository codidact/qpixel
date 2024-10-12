document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.js-copy-key').forEach(el => {
    el.addEventListener('click', ev => {
      const label = ev.target.closest('label');
      const field = document.querySelector(`#${label.getAttribute('for')}`);
      navigator.clipboard.writeText(field.value);
      field.focus();
      field.setSelectionRange(0, field.value.length);
    });
  });
});
