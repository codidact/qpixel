window.QPixel = window.QPixel || {};

QPixel._popups = {};

QPixel.Popup = class Popup {
  /**
   * Remove all currently open popups.
   */
  static destroyAll () {
    Object.values(QPixel._popups).forEach(popup => {
      popup.destroy();
    });
  }

  /**
   * Indicates whether the pressed key will be handled by the Popup class, and hence whether any
   * calling event handlers should ignore the key press.
   * @param code the event keyCode property
   */
  static isSpecialKey (code) {
    return [13, 27, 38, 40].includes(code);
  }

  /**
   * Get a popup for a given input field. You should generally use this method instead of directly
   * calling the constructor, as this accounts for pre-existing popups.
   * @param items an array of jQuery-wrappable elements to include - apply the `item` class to each one
   * @param field the parent textarea HTMLElement that this popup is for
   * @param cb a callback that will be called when an item is clicked - it will be passed the click event
   * @returns {QPixel.Popup}
   */
  static getPopup (items, field, cb) {
    const popupId = $(field).attr('data-popup');
    if (!!popupId) {
      const popup = QPixel._popups[popupId];
      popup.setCallback(cb);
      popup.updateItems(items);
      popup.updatePosition();
      return popup;
    }
    else {
      return new QPixel.Popup(items, field, cb);
    }
  }

  /**
   * Create a textarea 'suggestions'-type popup that drops down from the current caret position.
   * @param items an array of jQuery-wrappable elements to include - apply the `item` class to each one
   * @param field the parent textarea HTMLElement that this popup is for
   * @param cb a callback that will be called when an item is clicked - it will be passed the click event
   * @constructor
   */
  constructor (items, field, cb) {
    this.items = items;
    this.field = field;
    this.$field = $(this.field);
    this.callback = cb;
    this._id = Math.floor(Math.random() * 2**32).toString(16);
    this.$popup = $(`<div class="ta-popup" id="popup-${this._id}"></div>`);

    this._clickHandler = this.getClickHandler();
    this._keyHandler = this.getKeyHandler();

    this.items.forEach(el => {
      this.$popup.append(el);
      $(el).on('click', ev => {
        ev.stopPropagation();
        return !!this.callback ? this.callback(ev, this) : null;
      });
    });

    const caretPos = getCaretCoordinates(this.field, this.field.selectionStart);
    const fieldOffset = QPixel.offset(this.field);
    this.$popup.css({
      top: `${fieldOffset.top + caretPos.top + 20}px`,
      left: `${fieldOffset.left + caretPos.left}px`
    }).appendTo('body');

    $('body').on('click', this._clickHandler)
             .on('keydown', this._keyHandler);

    QPixel._popups[this._id] = this;
    this.$field.attr('data-popup', this._id);
  }

  /**
   * Update the items shown in the popup.
   * @param items a new list of items to display, in the same format as for getPopup
   */
  updateItems (items) {
    this.$popup.empty();
    items.forEach(el => {
      this.$popup.append(el);
      $(el).on('click', ev => {
        ev.stopPropagation();
        return !!this.callback ? this.callback(ev, this) : null;
      });
    });
  }

  /**
   * Update the position of the popup to the current cursor location.
   */
  updatePosition () {
    const caretPos = getCaretCoordinates(this.field, this.field.selectionStart);
    const fieldOffset = QPixel.offset(this.field);
    this.$popup.css({
      top: `${fieldOffset.top + caretPos.top + 20}px`,
      left: `${fieldOffset.left + caretPos.left}px`
    });
  }

  /**
   * Change the callback function to the provided function.
   * Necessary because if the callback is in a closure, old variable values (like cursor position)
   * will remain unless we update the callback to a new function in an updated closure.
   * @param cb the new callback function to apply
   */
  setCallback (cb) {
    this.callback = cb;
  }

  getActiveIdx () {
    const items = this.$popup.find('.item').toArray();
    const matching = items.filter(x => $(x).hasClass('active'));
    return matching.length > 0 ? items.indexOf(matching[0]) : null;
  }

  setActive (idx) {
    const items = this.$popup.find('.item');
    items.removeClass('active');
    items.eq((items.length + idx) % items.length).addClass('active');
  }

  /**
   * Completely remove this popup and unlink it from the input field.
   */
  destroy () {
    this.$popup.remove();
    this.$field.removeAttr('data-popup');
    delete QPixel._popups[this._id];
    $('body').off('click', this._clickHandler)
             .off('keydown', this._keyHandler);
  }

  /**
   * Internal. Handles a click anywhere on the body element outside of the popup.
   * Clicks inside the popup should have stopPropagation called.
   */
  getClickHandler () {
    const self = this;
    return function (ev) {
      self.destroy();
    };
  }

  /**
   * Internal. Handle a keypress anywhere on the body element.
   * @param ev the keydown Event
   */
  getKeyHandler (ev) {
    const self = this;
    return function (ev) {
      switch (ev.keyCode) {
        case 27: // Escape
          ev.stopPropagation();
          self.destroy();
          break;
        case 38: // Up arrow
          ev.stopPropagation();
          const activeUp = self.getActiveIdx();
          const startUp = activeUp === null ? 0 : activeUp;
          self.setActive(startUp - 1);
          break;
        case 40: // Down arrow
          ev.stopPropagation();
          const activeDown = self.getActiveIdx();
          const startDown = activeDown === null ? -1 : activeDown;
          self.setActive(startDown + 1);
          break;
        case 13: // Enter
          const selected = self.$popup.find('.item.active');
          console.log('enter, selected: ', selected);
          if (selected.length > 0) {
            ev.stopPropagation();
            ev.preventDefault();
            selected.click();
          }
          break;
      }
    }
  }
};
