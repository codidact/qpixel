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
   * @param {Element} element
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

  document.querySelectorAll('.post--content pre > code').forEach((child) => {
    const { parentElement: element } = child;

    if (!element) {
      return;
    }

    const { textContent } = element;

    // code blocks always have a trailing newline added
    const normalizedText = textContent.replace(/\n$/, '');

    if (!normalizedText) {
      return;
    }

    const numLines = normalizedText.split(/\r?\n/).length;

    if (numLines < 1) {
      return;
    }

    const button = createCopyButton(textContent, numLines === 1);
    const wrapper = wrapRelative(element);
    wrapper.prepend(button);
  });
});
