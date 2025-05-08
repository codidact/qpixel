document.addEventListener('DOMContentLoaded', () => {
  QPixel.DOM.addSelectorListener('input', '.js--warning-template-selection', (ev) => {
    const tgt = /** @type {HTMLInputElement} */ (ev.target);
    const input = /** @type {HTMLInputElement} */ (document.querySelector('.js--warning-template-target textarea'));
    input.value = atob(tgt.value);
  });
});
