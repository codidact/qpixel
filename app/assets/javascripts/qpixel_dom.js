window.QPixel = window.QPixel || {};

/**
 * @callback eventCallback
 * @param {Event} event The browser event.
 */

QPixel.DOM = {
  _delegatedListeners: [],
  _eventListeners: {},

  /**
   * Add a delegated event listener. Use when an event listener is required that will fire for elements added to the
   * DOM dynamically after the delegated listener is added.
   * @param {string} event An event name to listen for.
   * @param {string} selector A CSS selector representing elements on which to apply the listener.
   * @param {eventCallback} callback A callback function to pass to the event listener.
   */
  addDelegatedListener: (event, selector, callback) => {
    if (!QPixel.DOM._eventListeners[event]) {
      const listener = ev => {
        QPixel.DOM._delegatedListeners.filter(x => x.event === event).forEach(listener => {
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

  /**
   * Convenience method. Add an event listener to _all_ elements that currently match a selector.
   * @param {string} event An event name to listen for.
   * @param {string} selector A CSS selector representing elements on which to apply the listener.
   * @param {eventCallback} callback A callback function to pass to the event listener.
   */
  addSelectorListener: (event, selector, callback) => {
    document.querySelectorAll(selector).forEach(el => {
      el.addEventListener(event, callback);
    });
  },

  /**
   * Smoothly fade an element out of view, then remove it.
   * @param {Node|HTMLElement} element The element to fade out.
   * @param {number} duration A duration for the effect in milliseconds.
   */
  fadeOut: (element, duration) => {
    element.style.transition = `${duration}ms`;
    element.style.opacity = '0';
    setTimeout(() => {
      element.remove();
    }, duration);
  },

  /**
   * Helper to set the visibility of an element or list of elements. Uses display: none so should work with screen
   * readers.
   * @param {HTMLElement|HTMLElement[]|Node|Node[]|NodeList} elements An element or list/array of elements to set
   *  visibility for.
   * @param {boolean} visible Whether or not the elements should be visible.
   */
  setVisible: (elements, visible) => {
    if (!elements['forEach']) {
      elements = [elements];
    }
    elements.forEach(el => el.style.display = visible ? '' : 'none');
  }
};
