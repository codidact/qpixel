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

  QPixel.DOM.addSelectorListener('click', '.js-reply-button', ev => {
    const tgt = /** @type HTMLElement */(ev.currentTarget);
    const internal = tgt.dataset.internal;

    const widget = /** @type HTMLElement */(document.querySelector('.js-reply-widget'));
    const label = /** @type HTMLElement */(document.querySelector('.js-reply-label'));
    const form = /** @type HTMLFormElement */(document.querySelector('.js-reply-form'));

    widget.classList.add('hidden');

    if (internal === 'true') {
      widget.classList.add('is-yellow');
      label.innerText = 'Add your internal notes';
    }
    else {
      widget.classList.remove('is-yellow');
      label.innerText = 'Add your reply';
    }
    form.querySelector('input[name="internal"]').value = internal;

    widget.classList.remove('hidden');
  });

  QPixel.DOM.addSelectorListener('submit', '.js-reply-form', async ev => {
    ev.preventDefault();

    const tgt = /** @type HTMLFormElement */(ev.currentTarget);

    const data = Object.fromEntries(new FormData(tgt).entries());
    const resp = await QPixel.fetchJSON(tgt.action, data);
    const json = await resp.json();
    QPixel.handleJSONResponse(json, () => {
      document.querySelector('.js-comments').insertAdjacentHTML('beforeend', json.comment);
      tgt.reset();
      tgt.querySelector('input[type="submit"]').removeAttribute('disabled');
      document.querySelector('.js-reply-widget').classList.add('hidden');

      if (!json.can_add_more) {
        document.querySelector('.js-reply-container').remove();
      }
    });
  });
});