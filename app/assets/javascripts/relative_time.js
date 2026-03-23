document.addEventListener('DOMContentLoaded', () => {
  const updateInterval = 6e4; // updates relative time once a minute

  /**
   * @param {Node} el element to process
   */
  const processNode = (el) => {
    if (!QPixel.DOM?.isHTMLElement(el)) {
      return;
    }

    const { relstamp } = el.dataset;

    if (!relstamp) {
      return;
    }

    el.textContent = `${QPixel.DOM.formatTimestamp(relstamp)} (${moment(relstamp).fromNow()})`;
  };

  const updateRelativeTime = () => {
    document.querySelectorAll('[data-relstamp]').forEach(processNode);
    setTimeout(updateRelativeTime, updateInterval);
  };

  updateRelativeTime();

  new MutationObserver(() => {
    document.querySelectorAll('[data-relstamp]').forEach(processNode);
  }).observe(document, {
    attributes: true,
    subtree: true,
  });
});
