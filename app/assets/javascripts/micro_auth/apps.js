document.addEventListener('DOMContentLoaded', () => {
  QPixel.DOM.addSelectorListener('click', '.js-copy-key', (ev) => {
    const label = /** @type {HTMLElement} */ (ev.target).closest('label');
    const field = /** @type {HTMLInputElement} */ (document.querySelector(`#${label.getAttribute('for')}`));
    navigator.clipboard.writeText(field.value);
    field.focus();
    field.setSelectionRange(0, field.value.length);
  });
});
