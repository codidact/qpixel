/**
 * @type {PostValidator[]}
 */
const validators = [];

/** Counts notifications popped up at any time. */
let popped_modals_ct = 0;

window.QPixel = {
  createNotification: function (type, message) {
    // Some messages include a date stamp, `append_date` governs that.
    let append_date = false;
    let message_with_date = message;
    if (type === 'danger') {
      if (popped_modals_ct > 0) {
        /* At the time of writing, modals stack each one exactly on top of previous one, so repeating an errored action
         * over and over again is going to create multiple error modals in the same exact place. While this happens this
         * way, an user closing the error modal will not have an immediate visual action feedback if two or more error
         * modals have been printed. A date is stamped in order to cope with that. Could be anything. Probably a cycle
         * of different emoji characters would be cuter while having the purpose met. But if so, make sure character in
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
    $('<div></div>')
      .addClass('notice has-shadow-3 is-' + type)
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
      .on('click', function (_ev) {
        $(this).fadeOut(200, function () {
          $(this).remove();
          popped_modals_ct = popped_modals_ct > 0 ? (popped_modals_ct - 1) : 0;
        });
      })
      .appendTo(document.body);
    popped_modals_ct += 1;
  },

  offset: function (el) {
    const topLeft = $(el).offset();
    return {
      top: topLeft.top,
      left: topLeft.left,
      bottom: topLeft.top + $(el).outerHeight(),
      right: topLeft.left + $(el).outerWidth()
    };
  },

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

  addPrePostValidation: function (callback) {
    validators.push(callback);
  },

  validatePost: function (postText) {
    const results = validators.map((x) => x(postText));
    const valid = results.every((x) => x[0]);
    if (valid) {
      return [true, null];
    }
    else {
      return [false, results.map((x) => x[1]).flat()];
    }
  },

  replaceSelection: ($field, text) => {
    const prev = $field.val()?.toString();
    $field.val(prev.substring(0, $field[0].selectionStart) + text + prev.substring($field[0].selectionEnd));
  },

  /**
   * @type {QPixelFilter[]|null}
   */
  _filters: null,

  /**
   * Used to prevent launching multiple requests to /users/me
   * @type {Promise<Response>|null}
   */
  _pendingUserResponse: null,

  /**
   * @type {QPixelUser|null}
   */
  _user: null,

  _fetchUser () {
    if (QPixel._pendingUserResponse) {
      return QPixel._pendingUserResponse;
    }

    const myselfPromise = QPixel.fetch('/users/me', {
      headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      }
    });

    QPixel._pendingUserResponse = myselfPromise;

    return myselfPromise;
  },

  user: async () => {
    if (QPixel._user != null || document.body.dataset.userId === 'none') {
      return QPixel._user;
    }

    try {
      const resp = await QPixel._fetchUser();

      if (!resp.bodyUsed) {
        QPixel._user = await resp.json();
      }
    }
    finally {
      // ensures pending user is cleared regardless of network errors
      QPixel._pendingUserResponse = null;
    }

    return QPixel._user;
  },

  _preferences: null,

  _getPreferences: async () => {
    // Early return for the most frequent case (local variable already contains the preferences)
    if (QPixel._preferences != null) {
      return QPixel._preferences;
    }

    // Early return the preferences from storage unless null or undefined
    const key = QPixel._preferencesLocalStorageKey();
    const storedPreferences = QPixel.Storage?.get(key, { parse: true });
    if (storedPreferences) {
      return (QPixel._preferences = /** @type {UserPreferences} */(storedPreferences));
    }

    // If preferences are absent in storage, load them via AJAX
    await QPixel._cachedFetchPreferences();
    return QPixel._preferences;
  },

  preference: async (name, community = false) => {
    const user = await QPixel.user();

    if (!user) {
      return null;
    }

    let prefs = await QPixel._getPreferences();
    let value = community ? prefs?.community[name] : prefs?.global[name];

    // Note that null is a valid value for a preference, but undefined means we haven't fetched it.
    if (typeof value !== 'undefined') {
      return value;
    }
    // If we haven't fetched a preference, that probably means it's new - run a full re-fetch.
    await QPixel._cachedFetchPreferences();

    prefs = await QPixel._getPreferences();
    value = community ? prefs.community[name] : prefs.global[name];
    return value;
  },

  setPreference: async (name, value, community = false) => {
    const resp = await QPixel.fetchJSON('/users/me/preferences', { name, value, community }, {
      headers: { 'Accept': 'application/json' }
    });

    /** @type {QPixelResponseJSON<{ preferences: UserPreferences }>} */
    const data = await QPixel.parseJSONResponse(resp, 'Failed to save preference');

    QPixel.handleJSONResponse(data, (data) => {
      QPixel._updatePreferencesLocally(data.preferences);
    });
  },

  filters: async () => {
    if (this._filters == null) {
      // If they're still absent after loading from storage, load from the API.
      const resp = await QPixel.getJSON('/users/me/filters');
      const data = await resp.json();

      QPixel.Storage?.set('user_filters', data);
      this._filters = data;
    }

    return this._filters;
  },

  defaultFilter: async (categoryId) => {
    const user = await QPixel.user();

    if (!user) {
      return '';
    }
    
    const resp = await QPixel.getJSON(`/users/me/filters/default?category=${categoryId}`);

    const data = await resp.json();
    return data.name;
  },

  setFilter: async (name, filter, category, isDefault) => {
    const resp = await QPixel.fetchJSON('/users/me/filters',
      Object.assign(filter, {name, category, is_default: isDefault}), {
        headers: { 'Accept': 'application/json' }
      });

    /** @type {QPixelResponseJSON<{ filters: QPixelFilter[] }>} */
    const data = await QPixel.parseJSONResponse(resp, 'Failed to save filter');
    
    QPixel.handleJSONResponse(data, (data) => {
      this._filters = data.filters;
      QPixel.Storage?.set('user_filters', this._filters);
    });
  },

  deleteFilter: async (name, system = false) => {
    const resp = await QPixel.fetchJSON('/users/me/filters', { name, system }, {
      headers: { 'Accept': 'application/json' },
      method: 'DELETE'
    });

    /** @type {QPixelResponseJSON<{ filters: QPixelFilter[] }>} */
    const data = await QPixel.parseJSONResponse(resp, 'Failed to delete filter');

    QPixel.handleJSONResponse(data, (data) => {
      this._filters = data.filters;
      QPixel.Storage?.set('user_filters', this._filters);
    });
  },

  _preferencesLocalStorageKey: () => {
    const id = document.body.dataset.userId;
    const key = `user_${id}_preferences`;
    QPixel._preferencesLocalStorageKey = () => key;
    return key;
  },

  _cachedFetchPreferences: async () => {
    // No 'await' because we want the promise not its value
    const cachedPromise = QPixel._fetchPreferences();
    // Redefine this function to await this same initial promise on every subsequent call
    // This prevents multiple calls from triggering multiple redundant '_fetchPreferences' calls
    QPixel._cachedFetchPreferences = async () => {
      await cachedPromise;
    };
    // Remember to await the promise so the very first call does not return before '_fetchPreferences' returns
    await cachedPromise;
  },

  _fetchPreferences: async () => {
    const resp = await QPixel.getJSON('/users/me/preferences');
    const data = await resp.json();
    QPixel._updatePreferencesLocally(data);
  },

  _updatePreferencesLocally: (data) => {
    QPixel._preferences = data;
    const key = QPixel._preferencesLocalStorageKey();
    QPixel.Storage?.set(key, QPixel._preferences);
  },

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
  },

  fetch: async (uri, init) => {
    const defaultHeaders = {
      // X-Requested-With is necessary for request.xhr? to work
      'X-Requested-With': 'XMLHttpRequest',
    };

    const { headers = {}, ...restInit } = init ?? {};

        /** @type {RequestInit} */
        const requestInit = {
          headers: {
            ...defaultHeaders,
            ...headers,
          },
          credentials: 'include',
          ...restInit,
        };

    return fetch(uri, requestInit);
  },

  fetchJSON: async (uri, data, options = {}) => {
    const { headers = {}, ...restOptions } = options

    /** @type {RequestInit} */
    const requestInit = {
      method: 'POST',
      body: options.method === 'GET' ? void 0 : JSON.stringify(data),
      headers: {
          'Content-Type': 'application/json',
          ...headers,
      },
      ...restOptions,
    };

    return QPixel.fetch(uri, requestInit);
  },

  getJSON: async (uri, options = {}) => {
    const { headers = {} } = options ?? {};

    return QPixel.fetchJSON(uri, {}, {
      ...options,
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        ...headers,
      },
      method: 'GET',
    });
  },

  getComment: async (id) => {
    const resp = await QPixel.getJSON(`/comments/${id}`);

    const data = await resp.json();

    return data;
  },

  getNotifications: async () => {
    const resp = await QPixel.getJSON(`/users/me/notifications`, {
      headers: { 'Cache-Control': 'no-cache' }
    });

    const data = await resp.json();

    return data;
  },

  getThreadContent: async (id, options) => {
    const inline = options?.inline ?? true;
    const showDeleted = options?.showDeleted ?? false;

    const url = new URL(`/comments/thread/${id}/content`, window.location.origin);
    url.searchParams.append('inline', `${inline}`);
    url.searchParams.append('show_deleted_comments', `${showDeleted ? 1 : 0}`);

    const resp = await QPixel.fetch(url.toString(), {
      headers: { 'Accept': 'text/html' }
    });

    const content = await resp.text();

    return content;
  },

  getThreadsListContent: async (id) => {
    const url = new URL(`/comments/post/${id}`, window.location.origin);

    const resp = await QPixel.fetch(url.toString(), {
      headers: { 'Accept': 'text/html' }
    });

    const content = await resp.text();

    return content;
  },

  parseJSONResponse: async (response, errorMessage) => {
    try {
      const data = await response.json();

      return data;
    }
    catch (error) {
      if (response.ok) {
        console.error(error);
      }

      return {
        status: 'failed',
        message: errorMessage
      };
    }
  },

  handleJSONResponse: (data, onSuccess, onFinally) => {
    const is_modified = data.status === 'modified';
    const is_success = data.status === 'success';

    if (is_modified || is_success) {
      onSuccess(/** @type {Parameters<typeof onSuccess>[0]} */(data));
    }
    else {
      QPixel.createNotification('danger', data.message);
    }

    onFinally?.(data);

    return is_success;
  },

  flag: async (flag) => {
    const resp = await QPixel.fetchJSON(`/flags/new`, { ...flag }, {
      headers: { 'Accept': 'application/json' }
    });

    return QPixel.parseJSONResponse(resp, 'Failed to flag');
  },

  vote: async (postId, voteType) => {
    const resp = await QPixel.fetchJSON('/votes/new', {
      post_id: postId,
      vote_type: voteType
    });

    return QPixel.parseJSONResponse(resp, 'Failed to vote');
  },

  upload: async (url, form) => {
    const resp = await QPixel.fetch(url, {
      method: 'POST',
      body: new FormData(form)
    });

    return QPixel.parseJSONResponse(resp, 'Failed to upload');
  },

  archiveThread: async (id) => {
    const resp = await QPixel.fetchJSON(`/comments/thread/${id}/archive`, {}, {
      headers: { 'Accept': 'application/json' },
    });

    return QPixel.parseJSONResponse(resp, 'Failed to archive thread');
  },

  deleteThread: async (id) => {
    const resp = await QPixel.fetchJSON(`/comments/thread/${id}/delete`, {}, {
      headers: { 'Accept': 'application/json' },
    });

    return QPixel.parseJSONResponse(resp, 'Failed to delete thread');
  },

  followThread: async (id) => {
    const resp = await QPixel.fetchJSON(`/comments/thread/${id}/follow`, {}, {
      headers: { 'Accept': 'application/json' },
    });

    return QPixel.parseJSONResponse(resp, 'Failed to follow thread');
  },

  lockThread: async (id, duration) => {
    const resp = await QPixel.fetchJSON(`/comments/thread/${id}/lock`, {
      duration,
    });

    return QPixel.parseJSONResponse(resp, 'Failed to lock thread');
  },

  deleteComment: async (id) => {
    const resp = await QPixel.fetchJSON(`/comments/${id}/delete`, {}, {
      headers: { 'Accept': 'application/json' },
      method: 'DELETE'
    });

    return QPixel.parseJSONResponse(resp, 'Failed to delete comment');
  },

  followComments: async (postId) => {
    const resp = await QPixel.fetchJSON(`/comments/post/${postId}/follow`, {}, {
      headers: { 'Accept': 'application/json' }
    });

    return QPixel.parseJSONResponse(resp, 'Failed to follow post comments');
  },

  deleteDraft: async () => {
    const resp = await QPixel.fetchJSON(`/posts/delete-draft`, {
      path: location.pathname
    }, {
      headers: { 'Accept': 'application/json' }
    });

    return QPixel.parseJSONResponse(resp, 'Failed to delete post draft');
  },

  undeleteComment: async (id) => {
    const resp = await QPixel.fetchJSON(`/comments/${id}/delete`, {}, {
      headers: { 'Accept': 'application/json' },
      method: 'PATCH'
    });

    return QPixel.parseJSONResponse(resp, 'Failed to undelete comment');
  },

  unfollowComments: async (postId) => {
    const resp = await QPixel.fetchJSON(`/comments/post/${postId}/unfollow`, {}, {
      headers: { 'Accept': 'application/json' }
    });

    return QPixel.parseJSONResponse(resp, 'Failed to unfollow post comments');
  },

  renameTag: async (categoryId, tagId, name) => {
    const resp = await QPixel.fetchJSON(`/categories/${categoryId}/tags/${tagId}/rename`, { name }, {
      headers: { 'Accept': 'application/json' }
    });

    return QPixel.parseJSONResponse(resp, 'Failed to rename tag');
  },

  retractVote: async (id) => {
    const resp = await QPixel.fetchJSON(`/votes/${id}`, {}, { method: 'DELETE' });

    return QPixel.parseJSONResponse(resp, 'Failed to retract vote');
  },

  saveDraft: async (draft) => {
    const resp = await QPixel.fetchJSON('/posts/save-draft', {
      ...draft,
      path: location.pathname
    });

    return QPixel.parseJSONResponse(resp, 'Failed to save draft');
  },
};
