document.addEventListener('DOMContentLoaded', () => {
  QPixel.DOM.addSelectorListener('input', '.js--warning-template-selection', ev => {
    const tgt = ev.target;
    document.querySelector('.js--warning-template-target textarea').value = atob(tgt.value);
  });
});
