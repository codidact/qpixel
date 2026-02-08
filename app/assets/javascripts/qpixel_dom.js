window.QPixel ||= {};

(() => {
  /** @type {Record<string, ClassWatcherCallback[]>} */
  const classWatchers = {};

  new MutationObserver((records) => {
    const watchers = Object.entries(classWatchers);

    for (const { target } of records) {
      for (const [selector, callbacks] of watchers) {
        if (QPixel.DOM?.isHTMLElement(target) && target.matches(selector)) {
          for (const callback of callbacks) {
            callback(target);
          }
        }
      }
    }
  }).observe(document, {
    attributeFilter: ['class'],
    subtree: true
  });

  QPixel.DOM ||= {
    _delegatedListeners: [],
    _eventListeners: {},

    addDelegatedListener: (event, selector, callback) => {
      if (!QPixel.DOM._eventListeners[event]) {
        const listener = (ev) => {
          QPixel.DOM._delegatedListeners
            .filter((x) => x.event === event)
            .forEach((listener) => {
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

    getModifierState: (e) => {
      return !!e.altKey || !!e.ctrlKey || !!e.metaKey || !!e.shiftKey;
    },

    isHTMLElement: (node) => {
      return node instanceof HTMLElement;
    },

    setVisible: (elements, visible) => {
      if (!Array.isArray(elements)) {
        elements = [elements];
      }
      elements.forEach((el) => (el.style.display = visible ? '' : 'none'));
    },

    watchClass: (selector, callback) => {
      const callbacks = (classWatchers[selector] ||= []);
      callbacks.push(callback);
    }
  };
})();
