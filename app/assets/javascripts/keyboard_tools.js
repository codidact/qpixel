window.QPixel ||= {};

/**
 * @typedef {{
 *   key: string,
 *   text: string,
 *   if?: boolean
 * }} KeyboardShortcut
 */

document.addEventListener('DOMContentLoaded', async () => {
  const userLink = $('.header--item.is-complex.is-visible-on-mobile[href^="/users/"]').attr('href');
  const preference = await QPixel.preference('keyboard_tools');
  const keyboardToolsAreEnabled = preference === 'true';

  $('.js-keyboard_tools-status').text(keyboardToolsAreEnabled ? 'activated' : 'inactive');
  $('.js-keyboard_tools-toggle').click(() => {
    if (keyboardToolsAreEnabled) {
      QPixel.setPreference('keyboard_tools', 'false');
    } else {
      QPixel.setPreference('keyboard_tools', 'true');
    }
    window.location.reload();
  });

  if (!keyboardToolsAreEnabled) {
    return;
  }

  QPixel.Keyboard ||= {
    state: 'home',
    selectedItem: null,
    user_id: !!userLink ? parseInt(userLink.split('/').pop(), 10) : null,
    is_mod: !!$('.header--item[href="/mod/flags"]').length,
    categories: function () {
      const category_elements = $('a.category-header--tab');
      /**
       * @type {Record<string, string>}
       */
      const return_obj = {};
      category_elements.each(function () {
        return_obj[this.innerText] = this.getAttribute('href');
      });
      return return_obj;
    },
    dialog: function (msg) {
      this.dialogClose();
      const d = document.createElement('div');
      d.classList.add('__keyboard_help');
      d.innerText = msg;
      document.body.appendChild(d);
    },
    dialogClose: function () {
      $('.__keyboard_help').remove();
      this.state = 'home';
    },
    updateSelected: function () {
      $('.__keyboard_selected').removeClass('__keyboard_selected');
      if (this.selectedItem) {
        this.selectedItem.classList.add('__keyboard_selected');
        this.selectedItem.scrollIntoView({ behavior: 'smooth' });
        this.selectedItem.focus();

        this.selectedItemData = {
          type: /** @type {SelectedItemType} */ (this.selectedItem.getAttribute('data-ckb-item-type')),
          post_id: this.selectedItem.getAttribute('data-ckb-post-id')
        };
      }
    }
  };

  // Use html, so that all prior attempts to access keyup event have priority
  $('html').on('keyup', (e) => {
    if (e.target !== document.body) {
      return;
    }

    if (e.key === 'Escape') {
      QPixel.Keyboard.dialogClose();
    } else if (QPixel.Keyboard.state === 'home') {
      homeMenu(e);
    } else if (QPixel.Keyboard.state === 'goto') {
      gotoMenu(e);
    } else if (QPixel.Keyboard.state === 'goto/category') {
      categoryMenu(e);
    } else if (QPixel.Keyboard.state === 'goto/category-tags') {
      categoryTagsMenu(e);
    } else if (QPixel.Keyboard.state === 'goto/category-edits') {
      categorySuggestedEditsMenu(e);
    } else if (QPixel.Keyboard.state === 'tools') {
      toolsMenu(e);
    } else if (QPixel.Keyboard.state === 'tools/vote') {
      voteMenu(e);
    }
  });

  /**
   * @param {number} len
   * @returns {string}
   */
  const delimitShortcutsGroup = (len) => {
    return `${'='.repeat(len)}\n`;
  };

  /**
   * @param {KeyboardShortcut} shortcut
   * @param {number} [gap]
   * @returns {string}
   */
  const formatShortcut = ({ key, text }, gap = 4) => {
    return `${key}${' '.repeat(gap - (key.length - 1))}${text}`;
  };

  /**
   * @param {KeyboardShortcut[]} shortcuts
   * @param {number} [gap]
   * @returns {string}
   */
  const formatShortcuts = (shortcuts, gap = 4) => {
    return shortcuts.filter((s) => s.if === void 0 || s.if)
                    .map((s) => formatShortcut(s, gap))
                    .join('\n');
  };

  /**
   * Handles the "home" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const homeMenu = (e) => {
    const isHelp = e.key === '?';

    if (!isHelp && QPixel.DOM?.getModifierState(e)) {
      return;
    }

    if (isHelp) {
      /** @type {KeyboardShortcut[]} */
      const generalShortcuts = [
        { key: '?', text: 'Open this help' },
        { key: 'esc', text: 'Close this help' },
        { key: 'n', text: 'New post in the category' },
        { key: 's', text: 'Search for something' },
        { key: 'g', text: 'Go to ...' },
        { key: 'a', text: 'Go to answer field' }
      ];

      /** @type {KeyboardShortcut[]} */
      const selectionShortcuts = [
        { key: 'j', text: 'Move one item down' },
        { key: 'k', text: 'Move one item up' },
        { key: 't',
          text: 'Use a tool (on selection)',
          if: !!QPixel.Keyboard.selectedItemData && QPixel.Keyboard.selectedItemData.type !== 'link'
        }
      ];

      QPixel.Keyboard.dialog(
        'Keyboard Shortcuts\n' +
        delimitShortcutsGroup(33) +
        formatShortcuts(generalShortcuts, 4) +
        '\n\n' +
        'Selection shortcuts:\n\n' +
        formatShortcuts(selectionShortcuts, 4) +
        '\n\n' +
        'Selection shortcuts will select\n' +
        'first post, if none selected'
      );
    } else if (e.key === 'n') {
      const new_post_link = $('a.category-header--nav-item.is-button').attr('href');
      if (new_post_link) {
        window.location.href = new_post_link;
      }
    } else if (e.key === 'g') {
      /** @type {KeyboardShortcut[]} */
      const shortcuts = [
        { key: 'm', text: 'Main page' },
        { key: 'u', text: 'User list' },
        { key: 'h', text: 'Help' },
        { key: 'd', text: 'Dashboard' },
        { key: 'p', text: 'Your profile page' },
        { key: 'c', text: 'Category ...' },
        { key: 't', text: 'Tags of category ...' },
        { key: 'e', text: 'Suggested Edits of ...' },
        { key: 'f', text: 'Flags (mod only)', if: QPixel.Keyboard.is_mod }
      ];

      QPixel.Keyboard.dialog(
        'Go to ...\n' +
        delimitShortcutsGroup(26) +
        formatShortcuts(shortcuts, 3)
      );
      QPixel.Keyboard.state = 'goto';
    } else if (e.key === 'j') {
      if (QPixel.Keyboard.selectedItem == null) {
        QPixel.Keyboard.selectedItem = $('[data-ckb-list-item]:first-of-type')[0];
      } else {
        QPixel.Keyboard.selectedItem =
          $(QPixel.Keyboard.selectedItem).nextAll('[data-ckb-list-item]')[0] || QPixel.Keyboard.selectedItem;
      }
      QPixel.Keyboard.updateSelected();
    } else if (e.key === 'k') {
      if (QPixel.Keyboard.selectedItem == null) {
        QPixel.Keyboard.selectedItem = $('[data-ckb-list-item]:first-of-type')[0];
      } else {
        QPixel.Keyboard.selectedItem =
          $(QPixel.Keyboard.selectedItem).prevAll('[data-ckb-list-item]')[0] || QPixel.Keyboard.selectedItem;
      }
      QPixel.Keyboard.updateSelected();
    } else if (e.key === 't') {
      if (QPixel.Keyboard.selectedItem == null) {
        QPixel.Keyboard.selectedItem = $('[data-ckb-list-item]:first-of-type')[0];
      }
      QPixel.Keyboard.updateSelected();

      if (QPixel.Keyboard.selectedItemData.type === 'post') {
        /** @type {KeyboardShortcut[]} */
        const shortcuts = [
          { key: 'f', text: 'Flag' },
          { key: 'e', text: 'Edit' },
          { key: 'c', text: 'Comment' },
          { key: 'l', text: 'Get permalink' },
          { key: 'h', text: 'View history' },
          { key: 'v', text: 'Vote ...' },
          { key: 't', text: 'Use tools', if: QPixel.Keyboard.is_mod }
        ];

        QPixel.Keyboard.dialog(
          'Use tool ...\n' +
          delimitShortcutsGroup(17) +
          formatShortcuts(shortcuts, 3)
        );
        QPixel.Keyboard.state = 'tools';
      }
    } else if (e.key === 'a') {
      const cl = $('#answer_body_markdown');
      cl[0].scrollIntoView({ behavior: 'smooth' });
      cl.focus();
      QPixel.Keyboard.dialogClose();
    } else if (e.key === 'Enter') {
      if (QPixel.Keyboard.selectedItemData.type === 'link') {
        window.location.href = $(QPixel.Keyboard.selectedItem).find('[data-ckb-item-link]').attr('href');
      }
    }
  };

  /**
   * Handles the "goto" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const gotoMenu = (e) => {
    if (QPixel.DOM?.getModifierState(e)) {
      return;
    }

    if (e.key === 'm') {
      window.location.href = '/';
    } else if (e.key === 'u') {
      window.location.href = '/users';
    } else if (e.key === 'd') {
      window.location.href = '/dashboard';
    } else if (e.key === 'h') {
      window.location.href = '/help';
    } else if (e.key === 'p') {
      window.location.href = '/users/' + QPixel.Keyboard.user_id;
    } else if (e.key === 'f') {
      window.location.href = '/mod/flags';
    } else if (e.key === 't') {
      const data = Object.entries(QPixel.Keyboard.categories());
      let string_response = '';
      for (let i = 0; i < data.length; i++) {
        string_response += formatShortcut({
          key: (i + 1).toString(),
          text: data[i][0]
        }, 3) + '\n';
      }
      QPixel.Keyboard.dialog(
        'Go to tags of ...\n' +
        delimitShortcutsGroup(18) +
        string_response.trim()
      );
      QPixel.Keyboard.state = 'goto/category-tags';
    } else if (e.key === 'e') {
      const data = Object.entries(QPixel.Keyboard.categories());
      let string_response = '';
      for (let i = 0; i < data.length; i++) {
        string_response += formatShortcut({
          key: (i + 1).toString(),
          text: data[i][0]
        }, 3) + '\n';
      }
      QPixel.Keyboard.dialog(
        'Go to suggested edits of ...\n' +
        delimitShortcutsGroup(28) +
        string_response.trim()
      );
      QPixel.Keyboard.state = 'goto/category-edits';
    } else if (e.key === 'c') {
      const data = Object.entries(QPixel.Keyboard.categories());
      let string_response = '';
      for (let i = 0; i < data.length; i++) {
        string_response += formatShortcut({
          key: (i + 1).toString(),
          text: data[i][0]
        }, 3) + '\n';
      }
      QPixel.Keyboard.dialog(
        'Go to category ...\n' +
        delimitShortcutsGroup(18) +
        string_response.trim()
      );
      QPixel.Keyboard.state = 'goto/category';
    }
  };

  /**
   * Handles the "goto/category" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const categoryMenu = (e) => {
    if (QPixel.DOM?.getModifierState(e)) {
      return;
    }

    const number = parseInt(e.key);
    if (!isNaN(number)) {
      const data = QPixel.Keyboard.categories();
      const data_entries = Object.entries(data);

      const category = data_entries[number - 1];
      window.location.href = category[1];
    }
  };

  /**
   * Handles the "goto/category-tags" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const categoryTagsMenu = (e) => {
    if (QPixel.DOM?.getModifierState(e)) {
      return;
    }

    const number = parseInt(e.key);
    if (!isNaN(number)) {
      const data = Object.entries(QPixel.Keyboard.categories());

      const category = data[number - 1];
      window.location.href = category[1] + '/tags';
    }
  };

  /**
   * Handles the "goto/category-edits" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const categorySuggestedEditsMenu = (e) => {
    if (QPixel.DOM?.getModifierState(e)) {
      return;
    }

    const number = parseInt(e.key);
    if (!isNaN(number)) {
      const data = Object.entries(QPixel.Keyboard.categories());

      const category = data[number - 1];
      window.location.href = category[1] + '/suggested-edits';
    }
  };

  /**
   * Handles the "tools" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const toolsMenu = (e) => {
    if (QPixel.DOM?.getModifierState(e)) {
      return;
    }

    if (e.key === 'e') {
      window.location.href = $(QPixel.Keyboard.selectedItem)
        .find('.tools--item i.fa.fa-pencil-alt')
        .parent()
        .attr('href');
    } else if (e.key === 'h') {
      window.location.href = $(QPixel.Keyboard.selectedItem).find('.tools--item i.fa.fa-history').parent().attr('href');
    } else if (e.key === 'l') {
      window.location.href = $(QPixel.Keyboard.selectedItem).find('.tools--item i.fa.fa-link').parent().attr('href');
    } else if (e.key === 'c') {
      const cl = $(QPixel.Keyboard.selectedItem).find('.js-add-comment');
      cl.nextAll('form').css('display', 'block');
      cl.nextAll('form')[0].scrollIntoView({ behavior: 'smooth' });
      cl.nextAll('form').find('.js-comment-content').focus();
      QPixel.Keyboard.dialogClose();
    } else if (e.key === 'f') {
      const cl = $(QPixel.Keyboard.selectedItem).find('.post--action-dialog.js-flag-box');
      cl.addClass('is-active');
      cl[0].scrollIntoView({ behavior: 'smooth' });
      cl.find('.js-flag-comment').focus();
      QPixel.Keyboard.dialogClose();
    } else if (e.key === 'v') {
      /** @type {KeyboardShortcut[]} */
      const shortcuts = [
        { key: 'u', text: 'Up' },
        { key: 'd', text: 'Down' },
        { key: 'c', text: 'Close' }
      ];

      QPixel.Keyboard.dialog(
        'Vote ...\n' +
        delimitShortcutsGroup(9) +
        formatShortcuts(shortcuts, 3)
      );
      QPixel.Keyboard.state = 'tools/vote';
    } else if (e.key === 't') {
      let cl = $(QPixel.Keyboard.selectedItem).find('a.tools--item i.fa.fa-wrench').parent();
      cl = $(cl.attr('data-modal'));
      cl.toggleClass('is-active');
      cl.focus();
      QPixel.Keyboard.dialogClose();
    }
  };

  /**
   * Handles the "tools/vote" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  const voteMenu = (e) => {
    if (QPixel.DOM?.getModifierState(e)) {
      return;
    }

    if (e.key === 'u') {
      const cl = $(QPixel.Keyboard.selectedItem).find('.vote-button[data-vote-type="1"]');
      cl.click();
      QPixel.Keyboard.dialogClose();
    } else if (e.key === 'd') {
      const cl = $(QPixel.Keyboard.selectedItem).find('.vote-button[data-vote-type="-1"]');
      cl.click();
      QPixel.Keyboard.dialogClose();
    } else if (e.key === 'c') {
      const cl = $(QPixel.Keyboard.selectedItem).find('.post--action-dialog.js-close-box');
      cl.addClass('is-active');
      cl[0].scrollIntoView({ behavior: 'smooth' });
      cl.focus();
      QPixel.Keyboard.dialogClose();
    }
  };
});
