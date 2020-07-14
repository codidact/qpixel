const validators = [];

window.QPixel = {
  /**
   * Get the current CSRF anti-forgery token. Should be passed as the X-CSRF-Token header when
   * making AJAX POST requests.
   * @returns {string}
   */
  csrfToken: () => {
    const token = $('meta[name="csrf-token"]').attr('content');
    QPixel.csrfToken = () => token;
    return token;
  },

  /**
   * Create a notification popup - not an inbox notification.
   * @param type the type to apply to the popup - warning, danger, etc.
   * @param message the message to show
   */
  createNotification: function(type, message) {
    $("<div></div>")
    .addClass("notice has-shadow-3 is-" + type)
    .html('<button type="button" class="button is-close-button" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><p>' + message+"</p>")
    .css({
      'position': 'fixed',
      'top': "50px",
      'left': "50%",
      'transform': "translateX(-50%)",
      'z-index': 100,
      'width': '100%',
      'max-width': "800px",
      'cursor': 'pointer'
    })
    .on('click', function(ev) {
      $(this).fadeOut(200, function() {
        $(this).remove();
      });
    })
    .appendTo(document.body);
  },

  /**
   * Get the absolute offset of an element.
   * @param el the element for which to find the offset.
   * @returns {{top: integer, left: integer, bottom: integer, right: integer}}
   */
  offset: function(el) {
    const topLeft = $(el).offset();
    return {
      top: topLeft.top,
      left: topLeft.left,
      bottom: topLeft.top + $(el).outerHeight(),
      right: topLeft.left + $(el).outerWidth()
    };
  },

  /**
   * Add a button to the Markdown editor.
   * @param $buttonHtml the HTML content that the button should show - just text, if you like, or
   *                    something more complex if you want to.
   * @param shortName a short name for the action that will be used as the title and aria-label attributes.
   * @param callback a function that will be passed as the click event callback - should take one
   *                 parameter, which is the event object.
   */
  addEditorButton: function ($buttonHtml, shortName, callback) {
    const html = `<a href="javascript:void(0)" class="button is-muted is-outlined" title="${shortName}"
                     aria-label="${shortName}"></a>`;
    const $button = $(html).html($buttonHtml);

    const insertButton = () => {
      $('.js-markdown-tools').each((i, e) => {
        const $tgt = $(e);
        let $customGroup = $tgt.find('.button-list.js-custom-tools');
        if ($customGroup.length === 0) {
          $customGroup = $(`<div class="button-list is-gutterless js-custom-tools"></div>`);
          $customGroup.appendTo($tgt);
        }

        $button.clone().on('click', callback).appendTo($customGroup);
      });
    };

    insertButton();
  },

  /**
   * Add a validator that will be called before creating a post.
   * callback should take one parameter, the post text, and should return an array in
   * the following format:
   *
   * [
   *   true | false,  // is the post valid for this check?
   *   [
   *     { type: 'warning', message: 'warning message - will not block posting' },
   *     { type: 'error', message: 'error message - will block posting' }
   *   ]
   * ]
   */
  addPrePostValidation: function (callback) {
    validators.push(callback);
  },

  /**
   * Internal. Called just before a post is sent to the server to validate that it passes
   * all custom checks.
   */
  validatePost: function (postText) {
    const results = validators.map(x => x(postText));
    const valid = results.every(x => x[0]);
    if (valid) {
      return [true, null];
    }
    else {
      return [false, results.map(x => x[1]).flat()];
    }
  },

  /**
   * Replace the selected text in an input field with a provided replacement.
   * @param $field the field in which to replace text
   * @param text the text with which to replace the selection
   */
  replaceSelection: ($field, text) => {
    const prev = $field.val();
    $field.val(prev.substring(0, $field[0].selectionStart) + text + prev.substring($field[0].selectionEnd));
  },

  _user: null,
  user: async () => {
    if (QPixel._user) return QPixel._user;
    const resp = await fetch('/users/me', {
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    QPixel._user = await resp.json();
    return QPixel._user;
  }
};