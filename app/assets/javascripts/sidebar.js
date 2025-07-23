document.addEventListener('DOMContentLoaded', () => {
  QPixel.DOM.addDelegatedListener('click', '.js-widget-hide, .js-widget-hide *', ev => {
    let tgt = /** @type {HTMLElement} */ (ev.target);
    if (!tgt.classList.contains('js-widget-hide')) {
      tgt = tgt.closest('.js-widget-hide');
    }
    const icon = tgt.querySelector('i');
    const widget = /** @type {HTMLElement} */ (tgt.closest('.widget'));
    const isHidden = widget.dataset.collapsed === 'true';
    if (isHidden) {
      widget.querySelectorAll('.widget--body').forEach(el => {
        el.classList.remove('hiding', 'hidden');
      });
      icon.classList.remove('fa-chevron-down');
      icon.classList.add('fa-chevron-up');
      widget.dataset.collapsed = 'false';
    }
    else {
      widget.querySelectorAll('.widget--body').forEach(el => {
        el.classList.add('hiding');
        setTimeout(() => el.classList.add('hidden'), 200);
      });
      icon.classList.remove('fa-chevron-up');
      icon.classList.add('fa-chevron-down');
      widget.dataset.collapsed = 'true';
    }
  });
});
