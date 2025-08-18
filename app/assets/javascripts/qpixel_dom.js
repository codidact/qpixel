window.QPixel = window.QPixel || {};

QPixel.DOM = {
  _delegatedListeners: [],
  _eventListeners: {},

  addDelegatedListener: (event, selector, callback) => {
    if (!QPixel.DOM._eventListeners[event]) {
      const listener = (ev) => {
        QPixel.DOM._delegatedListeners.filter((x) => x.event === event).forEach((listener) => {
          if (ev.target.matches(listener.selector)) {
            listener.callback(ev);
          }
        });
      };
      document.addEventListener(event, listener);
      QPixel.DOM._eventListeners[event] = listener;
    }
    QPixel.DOM._delegatedListeners.push({ event, selector, callback });
  },

  addSelectorListener: (event, selector, callback) => {
    document.querySelectorAll(selector).forEach((el) => {
      el.addEventListener(event, callback);
    });
  },

  fadeOut: (element, duration) => {
    element.style.transition = `${duration}ms`;
    element.style.opacity = '0';
    setTimeout(() => {
      element.remove();
    }, duration);
  },

  isHTMLElement: (node) => {
    return node instanceof HTMLElement;
  },

  setVisible: (elements, visible) => {
    if (!Array.isArray(elements)) {
      elements = [elements];
    }
    elements.forEach((el) => el.style.display = visible ? '' : 'none');
  }
};
