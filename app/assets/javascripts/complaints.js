window.addEventListener('DOMContentLoaded', () => {
  QPixel.DOM.addSelectorListener('change', 'input[name="report_type"]', ev => {
    const value = /** @type HTMLInputElement */(document.querySelector('input[name="report_type"]:checked')).value;
    document.querySelectorAll(`[data-report-type="${value}"]`).forEach(el => {
      el.classList.remove('hidden');
      el.removeAttribute('disabled');
    });
    document.querySelectorAll(`[data-report-type]:not([data-report-type="${value}"])`).forEach(el => {
      el.classList.add('hidden');
      el.setAttribute('disabled', 'disabled');
    });
  });
});