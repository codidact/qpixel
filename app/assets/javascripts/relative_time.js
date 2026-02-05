document.addEventListener('DOMContentLoaded', () => {
  const updateInterval = 6e4; // updates relative time once a minute
  let lastRunAt = -1;

  /**
   * @type {FrameRequestCallback}
   */
  const updateRelativeTime = (timestamp) => {
    const elapsed = timestamp - lastRunAt;

    if (elapsed < updateInterval && lastRunAt !== -1) {
      requestAnimationFrame(updateRelativeTime);
      return;
    }

    document.querySelectorAll('[data-relstamp]').forEach((el) => {
      if (!QPixel.DOM?.isHTMLElement(el)) {
        return;
      }

      const { relstamp } = el.dataset;

      if (!relstamp) {
        return;
      }

      el.textContent = `${QPixel.DOM.formatTimestamp(relstamp)} (${moment(relstamp).fromNow()})`;
    });

    lastRunAt = timestamp;
    requestAnimationFrame(updateRelativeTime);
  };

  requestAnimationFrame(updateRelativeTime);
});
