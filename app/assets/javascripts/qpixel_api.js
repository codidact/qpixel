const validators = [];

/** Counts notifications popped up at any time. */
let popped_modals_ct = 0;

/**
 * @typedef {{
 *  min_score: number | null,
 *  max_score: number | null,
 *  min_answers: number | null,
 *  max_answers: number | null,
 *  include_tags: [string, number][],
 *  exclude_tags: [string, number][],
 *  status: 'any' | 'closed' | 'open',
 *  system: boolean,
 * }} Filter
 *
 * @typedef {{
 *  id: number,
 *  username: string,
 *  is_moderator: boolean,
 *  is_admin: boolean,
 *  is_global_moderator: boolean,
 *  is_global_admin: boolean,
 *  trust_level: number,
 *  se_acct_id: string | null,
 * }} User
 */

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
    // Some messages include a date stamp, `append_date` governs that.
    let append_date = false;
    let message_with_date = message;
    if (type === 'danger') {
      if (popped_modals_ct > 0) {
        /* At the time of writing, modals stack each one exactly on top of previous one, so repeating an errored action
         * over and over again is going to create multiple error modals in the same exact place. While this happens this
         * way, an user closing the error modal will not have an immediate visual action feedback if two or more error
         * modals have been printed. A date is stamped in order to cope with that. Could be anything. Probably a cycle
         * of different emoji characters would be cuter while having the purpose met. But if so make sure character in
         * step `i` is actually different than character in step `i + 1`. And then you could print an emoji just every
         * time a modal is popped up, not just from the second one; removing `message_with_date`, using only `message`,
         * and removing `append_date` and the different situations guarded by it. */
        append_date = true;
      }
    }
    if (append_date) {
      message_with_date += ' (' + new Date(Date.now()).toISOString() + ')';
    }
    const span = '<span aria-hidden="true">&times;</span>';
    const button = ('<button type="button" class="button is-close-button" data-dismiss="alert" aria-label="Close">' +
        span + '</button>');
    $("<div></div>")
    .addClass("notice has-shadow-3 is-" + type)
    .html(button + '<p>' + message_with_date + '</p>')
    .css({
      'position': 'fixed',
      'top': '50px',
      'left': '50%',
      'transform': 'translateX(-50%)',
      'width': '100%',
      'max-width': '800px',
      'cursor': 'pointer'
    })
    .on('click', function(ev) {
      $(this).fadeOut(200, function() {
        $(this).remove();
        popped_modals_ct = popped_modals_ct > 0 ? (popped_modals_ct - 1) : 0;
      });
    })
    .appendTo(document.body);
    popped_modals_ct += 1;
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

  /**
   * Used to prevent launching multiple requests to /users/me
   * @type {Promise<Response>|null}
   */
  _pendingUserResponse: null,

  /**
   * @type {User|null}
   */
  _user: null,

  /**
   * FIFO-style fetch wrapper for /users/me requests
   * @returns {Promise<Response>}
   */
  _fetchUser() {
    if(QPixel._pendingUserResponse) {
        return QPixel._pendingUserResponse
    }

    const myselfPromise = fetch('/users/me', {
        credentials: 'include',
        headers: {
          'Accept': 'application/json'
        }
    });

    QPixel._pendingUserResponse = myselfPromise;

    return myselfPromise
  },

  /**
   * Get the user object for the current user.
   * @returns {Promise<User>} a JSON object containing user details
   */
  user: async () => {
    if (QPixel._user != null || document.body.dataset.userId === 'none') {
      return QPixel._user;
    }

    try {
        const resp = await QPixel._fetchUser();

        if(!resp.bodyUsed) {
            QPixel._user = await resp.json();
        }
    } finally {
        // ensures pending user is cleared regardless of network errors
        QPixel._pendingUserResponse = null;
    }

    return QPixel._user;
  },

  _preferences: null,

  /**
   * Get an object containing the current user's preferences. Loads, in order of precedence, from local variable,
   * localStorage, or Redis via AJAX.
   * @returns {Promise<Object>} a JSON object containing user preferences
   */
  _getPreferences: async () => {
    // Early return for the most frequent case (local variable already contains the preferences)
    if (QPixel._preferences != null) {
      return QPixel._preferences;
    }
    // Early return the preferences from localStorage unless null or undefined
    const key = QPixel._preferencesLocalStorageKey();
    const localStoragePreferences = (key in localStorage)
                                    ? JSON.parse(localStorage[key])
                                    : null;
    if (localStoragePreferences != null) {
      QPixel._preferences = localStoragePreferences;
      return QPixel._preferences;
    }
    // Preferences are still null (or undefined) after loading from localStorage, so we're probably on a site we
    // haven't loaded them for yet. Load from Redis via AJAX.
    await QPixel._cachedFetchPreferences();
    return QPixel._preferences;
  },

  /**
   * Get a single user preference by name.
   * @param name the name of the requested preference
   * @param community is the requested preference community-local (true), or network-wide (false)?
   * @returns {Promise<*>} the value of the requested preference
   */
  preference: async (name, community = false) => {
    const user = await QPixel.user();

    if(!user) {
        return null
    }

    let prefs = await QPixel._getPreferences();
    let value = community ? prefs.community[name] : prefs.global[name];

    // Note that null is a valid value for a preference, but undefined means we haven't fetched it.
    if (typeof(value) !== 'undefined') {
      return value;
    }
    // If we haven't fetched a preference, that probably means it's new - run a full re-fetch.
    await QPixel._cachedFetchPreferences();

    prefs = await QPixel._getPreferences();
    value = community ? prefs.community[name] : prefs.global[name];
    return value;
  },

  /**
   * Set a user preference by name to the value provided.
   * @param name the name of the preference to set
   * @param value the value to set to - must respond to toString() for localStorage and Redis
   * @param community is this preference community-local (true), or network-wide (false)?
   * @returns {Promise<void>}
   */
  setPreference: async (name, value, community = false) => {
    const resp = await fetch('/users/me/preferences', {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name, value, community })
    });
    const data = await resp.json();
    if (data.status !== 'success') {
      console.error(`Preference persist failed (${name})`);
      console.error(resp);
    }
    else {
      QPixel._updatePreferencesLocally(data.preferences);
    }
  },

  /**
   * @returns {Promise<Record<string, Filter>>}
   */
  filters: async () => {
    if (this._filters == null) {
      // If they're still null (or undefined) after loading from localStorage, we're probably on a site we haven't
      // loaded them for yet. Load via AJAX.
      const resp = await fetch('/users/me/filters', {
        credentials: 'include',
        headers: {
          'Accept': 'application/json'
        }
      });
      const data = await resp.json();
      localStorage['qpixel.user_filters'] = JSON.stringify(data);
      this._filters = data;
    }

    return this._filters;
  },

  /**
   * Fetches default user filter for a given category
   * @param categoryId id of the category to fetch
   * @returns {Promise<string>}
   */
  defaultFilter: async (categoryId) => {
    const user = await QPixel.user();

    if(!user) {
        return '';
    }

    const resp = await fetch(`/users/me/filters/default?category=${categoryId}`, {
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });

    const data = await resp.json();
    return data.name;
  },

  setFilterAsDefault: async (categoryId, name) => {
    const resp = await fetch(`/categories/${categoryId}/filters/default`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name })
    });
  },

  setFilter: async (name, filter, category, isDefault) => {
    const resp = await fetch('/users/me/filters', {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(Object.assign(filter, { name, category, is_default: isDefault }))
    });
    const data = await resp.json();
    if (data.status !== 'success') {
      console.error(`Filter persist failed (${name})`);
      console.error(resp);
    }
    else {
      this._filters = data.filters;
      localStorage['qpixel.user_filters'] = JSON.stringify(this._filters);
    }
  },

  deleteFilter: async (name, system = false) => {
    const resp = await fetch('/users/me/filters', {
      method: 'DELETE',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name, system })
    });
    const data = await resp.json();
    if (data.status !== 'success') {
      console.error(`Filter deletion failed (${name})`);
      console.error(resp);
    }
    else {
      this._filters = data.filters;
      localStorage['qpixel.user_filters'] = JSON.stringify(this._filters);
    }
  },

  /**
   * Get the key to use for storing user preferences in localStorage, to avoid conflating users
   * @returns string the localStorage key
   */
  _preferencesLocalStorageKey: () => {
    const id = document.body.dataset.userId;
    const key = `qpixel.user_${id}_preferences`;
    QPixel._preferencesLocalStorageKey = () => key;
    return key;
  },

  /**
   * Call _fetchPreferences but only the first time to prevent redundant HTTP requests
   * @returns {Promise<void>}
   */
  _cachedFetchPreferences: async () => {
    // No 'await' because we want the promise not its value
    const cachedPromise = QPixel._fetchPreferences();
    // Redefine this function to await this same initial promise on every subsequent call
    // This prevents multiple calls from triggering multiple redundant '_fetchPreferences' calls
    QPixel._cachedFetchPreferences = async () => {
      await cachedPromise;
    }
    // Remember to await the promise so the very first call does not return before '_fetchPreferences' returns
    await cachedPromise;
  },

  /**
   * Update local variable _preferences and localStorage with an AJAX call for the user preferences
   * @returns {Promise<void>}
   */
  _fetchPreferences: async () => {
    const resp = await fetch('/users/me/preferences', {
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    const data = await resp.json();
    QPixel._updatePreferencesLocally(data);
  },

  /**
   * Set local variable _preferences and localStorage to new preferences data
   * @param data an object, containing the new preferences data
   */
  _updatePreferencesLocally: data => {
    QPixel._preferences = data;
    const key = QPixel._preferencesLocalStorageKey();
    localStorage[key] = JSON.stringify(QPixel._preferences);
  },

  /**
   * Get the word in a string that the given position is in, and the position within that word.
   * @param splat an array, containing the string already split by however you define a "word"
   * @param posIdx the index to search for
   * @returns {[string, number]} the word the given position is in, and the position within that word
   */
  currentCaretSequence: (splat, posIdx) => {
    let searchIdx = 0;
    let splatIdx = 0;
    let posInSeq;
    let currentSequence;
    do {
      currentSequence = splat[splatIdx];
      posInSeq = posIdx - (splatIdx === 0 ? searchIdx : searchIdx + 1);
      searchIdx += currentSequence.length + (splatIdx === 0 ? 0 : 1);
      splatIdx += 1;
    } while (searchIdx < posIdx);
    return [currentSequence, posInSeq];
  }
};
