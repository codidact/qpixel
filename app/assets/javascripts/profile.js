document.addEventListener('DOMContentLoaded', () => {
  document.querySelector('.js-submit-profile-edit')?.addEventListener('click', (ev) => {
    const { target } = ev;

    if (!QPixel.DOM?.isHTMLElement(target)) {
      return;
    }

    const profileForm = target.closest('form');

    profileForm?.querySelectorAll('input[type=file]').forEach((el) => {
      const files = /** @type {HTMLInputElement} */ (el).files;

      // TODO: MaxUploadSize is a site setting and can be changed
      if (files.length > 0 && files[0].size >= 2000000) {
        if (!ev.defaultPrevented) {
          ev.preventDefault();
        }

        const maxSizeCaption = profileForm?.querySelector(`.js-max-size[for='${el.id}']`);

        if (!maxSizeCaption) {
          return;
        }

        maxSizeCaption.classList.add('has-color-red-700', 'error-shake');
        setTimeout(() => maxSizeCaption?.classList.remove('error-shake'), 1000);
      }
    });
  });
});
