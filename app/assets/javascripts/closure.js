document.addEventListener('DOMContentLoaded', async () => {
  QPixel.DOM.addSelectorListener('click', '.js-close-question', async (ev) => {
    ev.preventDefault();

    const self = ev.target;
    const activeRadio = self.closest('.js-close-box').querySelector("input[type='radio'][name='close-reason']:checked");

    if (!activeRadio) {
      QPixel.createNotification('danger', 'You must select a close reason.');
      return;
    }

    const otherPostInput = activeRadio.closest('.widget--body').querySelector('.js-close-other-post');
    const otherPostRequired = activeRadio.dataset.rop === 'true';
    const data = {
      'reason_id': parseInt(activeRadio.value, 10),
      'other_post': otherPostInput?.value
      // option will be silently discarded if no input element
    };

    if (data['other_post'] && data['other_post'].match(/\/[0-9]+$/)) {
      data['other_post'] = data['other_post'].replace(/.*\/([0-9]+)$/, "$1");
    }

    if (!otherPostInput?.value && otherPostRequired) {
      QPixel.createNotification('danger', 'You must enter an ID or URL to another post.');
      return;
    }

    const req = await fetch(`/posts/${self.dataset.postId}/close`, {
      method: 'POST',
      body: JSON.stringify(data),
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      }
    });
    if (req.status === 200) {
      const res = await req.json();
      if (res.status === 'success') {
        location.reload();
      }
      else {
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${response.message}`);
      }
    }
    else {
      QPixel.createNotification('danger', `<strong>Failed:</strong> ${req.status}`);
    }
  });
});
