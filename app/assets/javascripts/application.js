// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require chartkick
//= require Chart.bundle
//= require jquery_ujs
//= require_tree .

document.addEventListener('DOMContentLoaded', async () => {
  QPixel.DOM.addSelectorListener('click', 'a.flag-dialog-link', (ev) => {
    ev.preventDefault();
    const flagDialog = ev.target.closest('.post--body').querySelector('.js-flag-box');
    flagDialog.classList.toggle('is-active');
  });

  QPixel.DOM.addSelectorListener('click', '.close-dialog-link', (ev) => {
    ev.preventDefault();
    const dialog = ev.target.closest('.post--body').querySelector('.js-close-box');
    dialog.classList.toggle('is-active');
  });

  QPixel.DOM.addSelectorListener('click', '.show-all-flags-dialog-link', (ev) => {
    ev.preventDefault();
    const dialog = ev.target.closest('.post--body').querySelector('.js-flags');
    dialog.classList.toggle('is-active');
  });

  QPixel.DOM.addSelectorListener('click', '.flag-resolve', async (ev) => {
    ev.preventDefault();
    const tgt = ev.target;
    const id = tgt.dataset.flagId;
    const data = {
      result: tgt.dataset.result,
      message: tgt.parentNode.parentNode.querySelector('.flag-resolve-comment').value
    };

    const req = await fetch(`/mod/flags/${id}/resolve`, {
      method: 'POST',
      body: JSON.stringify(data),
      credentials: 'include',
      headers: { 'X-CSRF-Token': QPixel.csrfToken() }
    });
    if (req.status === 200) {
      const res = await req.json();
      if (res.status === 'success') {
        const flagContainer = tgt.parentNode.parentNode.parentNode;
        QPixel.DOM.fadeOut(flagContainer, 200);
      }
      else {
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${res.message}`);
      }
    }
    else {
      QPixel.createNotification('danger', `<strong>Failed:</strong> Unexpected status (${req.status})`);
    }
  });

  if (document.cookie.indexOf('dismiss_fvn') === -1) {
    QPixel.DOM.addSelectorListener('click', '#fvn-dismiss', (_ev) => {
      document.cookie = 'dismiss_fvn=true; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT';
    });
  }
});

const cssVar = (name) => window.getComputedStyle(document.documentElement).getPropertyValue(`--${name}`).trim();

Chartkick.setDefaultOptions({
  colors: Array.from(Array(5).keys()).map((idx) => cssVar(`data-${idx}`))
});
