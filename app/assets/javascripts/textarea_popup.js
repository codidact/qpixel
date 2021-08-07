window.QPixel = window.QPixel || {};

QPixel._popups = {};

QPixel.Popup = class Popup {
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
        return !!this.callback ? this.callback(ev) : null;
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
    this.$field.attr('data-popup', this.id);
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
        return !!this.callback ? this.callback(ev) : null;
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
      if (ev.keyCode === 27) {
        ev.stopPropagation();
        self.destroy();
      }
    }
  }
};
