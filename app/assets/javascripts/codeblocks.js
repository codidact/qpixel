document.addEventListener('DOMContentLoaded', () => {
  /**
   * @param {string} content
   * @returns {HTMLButtonElement}
   */
  const createCopyButton = (content, isSmall = false) => {
    const button = document.createElement('button');
    button.classList.add('copy-button', 'button', 'is-muted', 'is-outlined', 'has-margin-2');
    button.textContent = 'Copy';

    if (isSmall) {
      button.classList.add('is-small');
    }

    button.addEventListener('click', async () => {
      const originalButtonText = button.textContent;

      try {
        await navigator.clipboard.writeText(content);
        button.textContent = 'Copied!';
      }
      catch (e) {
        console.warn(e);
        button.textContent = 'Failed!';
      }
      finally {
        setTimeout(() => {
          button.textContent = originalButtonText;
        }, 2000);
      }
    });

    return button;
  };

  /**
   * @param {HTMLElement} element
   * @returns {HTMLDivElement}
   */
  const wrapRelative = (element) => {
    const wrapper = document.createElement('div');
    wrapper.style.position = 'relative';
    wrapper.append(element.cloneNode(true));
    element.replaceWith(wrapper);
    return wrapper;
  };

  if (!window.isSecureContext) {
    return;
  }

  $('.post--content pre > code')
    .parent()
    .each(function (_, element) {
      const $content = $(this).text();
      const numLines = $content.trim().split(/\r?\n/).length;

      const button = createCopyButton($content, numLines <= 1);
      const wrapper = wrapRelative(element);
      wrapper.prepend(button);
    });
});
