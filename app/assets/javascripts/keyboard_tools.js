window.QPixel ||= {};

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
  $('html').on('keyup', function (e) {
    if (e.target !== document.body) return;
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
   * Checks common modifier states on a given keyboard event
   * @param {JQuery.KeyboardEventBase} e
   * @returns {boolean}
   */
  const getModifierState = (e) => {
    return !!e.altKey || !!e.ctrlKey || !!e.metaKey || !!e.shiftKey;
  };

  /**
   * Handles the "home" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function homeMenu(e) {
    const isHelp = e.key === '?';

    if (!isHelp && getModifierState(e)) {
      return;
    }

    if (isHelp) {
      QPixel.Keyboard.dialog(
        'Keyboard Shortcuts\n' +
          '===========================\n' +
          '?   Open this help\n' +
          'esc Close this help\n' +
          'n   New post\n' +
          '    (in current category)\n' +
          's   Search for something\n' +
          'g   Go to a page...\n\n' +
          'a   Go to answer field\n\n' +
          'Selection shortcuts:\n\n' +
          'j   Move one item down\n' +
          'k   Move one item up\n' +
          't  Use a tool (on selection)\n\n' +
          '(Selection shortcuts will select\n' +
          'first post, if none selected)'
      );
    } else if (e.key === 'n') {
      const new_post_link = $('a.category-header--nav-item.is-button').attr('href');
      if (new_post_link) {
        window.location.href = new_post_link;
      }
    } else if (e.key === 'g') {
      QPixel.Keyboard.dialog(
        'Go to ...\n' +
          '=========\n' +
          'm   Main page\n' +
          'u   User list\n' +
          'h   Help\n' +
          'd   Dashboard\n' +
          'p   Your profile page\n' +
          'c   Category ...\n' +
          't   Tags of category ...\n' +
          'e   Suggested Edits of category ...' +
          (QPixel.Keyboard.is_mod ? '\nf   Flags (mod only)' : '')
      );
      QPixel.Keyboard.state = 'goto';
    } else if (e.key === 'k') {
      if (QPixel.Keyboard.selectedItem == null) {
        QPixel.Keyboard.selectedItem = $('[data-ckb-list-item]:first-of-type')[0];
      } else {
        QPixel.Keyboard.selectedItem =
          $(QPixel.Keyboard.selectedItem).nextAll('[data-ckb-list-item]')[0] || QPixel.Keyboard.selectedItem;
      }
      QPixel.Keyboard.updateSelected();
    } else if (e.key === 'j') {
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
        QPixel.Keyboard.dialog(
          'Use tool ...\n' +
            '============\n' +
            'f  Flag\n' +
            'e  Edit\n' +
            'c  Comment\n' +
            'l  Get permalink\n' +
            'h  View history\n' +
            'v  Vote ...' +
            (QPixel.Keyboard.is_mod ? '\nt  Use tools' : '')
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
  }

  /**
   * Handles "goto" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function gotoMenu(e) {
    if (getModifierState(e)) {
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
        const entry = data[i];
        string_response += i + 1 + '  ' + entry[0] + '\n';
      }
      QPixel.Keyboard.dialog('Go to tags of category ...\n' + '==================\n' + string_response.trim());
      QPixel.Keyboard.state = 'goto/category-tags';
    } else if (e.key === 'e') {
      const data = Object.entries(QPixel.Keyboard.categories());
      let string_response = '';
      for (let i = 0; i < data.length; i++) {
        const entry = data[i];
        string_response += i + 1 + '  ' + entry[0] + '\n';
      }
      QPixel.Keyboard.dialog(
        'Go to suggested edits of category ...\n' + '==================\n' + string_response.trim()
      );
      QPixel.Keyboard.state = 'goto/category-edits';
    } else if (e.key === 'c') {
      const data = Object.entries(QPixel.Keyboard.categories());
      let string_response = '';
      for (let i = 0; i < data.length; i++) {
        const entry = data[i];
        string_response += i + 1 + '  ' + entry[0] + '\n';
      }
      QPixel.Keyboard.dialog('Go to category ...\n' + '==================\n' + string_response.trim());
      QPixel.Keyboard.state = 'goto/category';
    }
  }

  /**
   * Handles the "goto/category" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function categoryMenu(e) {
    if (getModifierState(e)) {
      return;
    }

    const number = parseInt(e.key);
    if (!isNaN(number)) {
      const data = QPixel.Keyboard.categories();
      const data_entries = Object.entries(data);

      const category = data_entries[number - 1];
      window.location.href = category[1];
    }
  }

  /**
   * Handles the "goto/category-tags" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function categoryTagsMenu(e) {
    if (getModifierState(e)) {
      return;
    }

    const number = parseInt(e.key);
    if (!isNaN(number)) {
      const data = Object.entries(QPixel.Keyboard.categories());

      const category = data[number - 1];
      window.location.href = category[1] + '/tags';
    }
  }

  /**
   * Handles the "goto/category-edits" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function categorySuggestedEditsMenu(e) {
    if (getModifierState(e)) {
      return;
    }

    const number = parseInt(e.key);
    if (!isNaN(number)) {
      const data = Object.entries(QPixel.Keyboard.categories());

      const category = data[number - 1];
      window.location.href = category[1] + '/suggested-edits';
    }
  }

  /**
   * Handles the "tools" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function toolsMenu(e) {
    if (getModifierState(e)) {
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
      QPixel.Keyboard.dialog('Vote ...\n' + '========\n' + 'u  Up\n' + 'd  Down\n' + 'c  Close');
      QPixel.Keyboard.state = 'tools/vote';
    } else if (e.key === 't') {
      let cl = $(QPixel.Keyboard.selectedItem).find('a.tools--item i.fa.fa-wrench').parent();
      cl = $(cl.attr('data-modal'));
      cl.toggleClass('is-active');
      cl.focus();
      QPixel.Keyboard.dialogClose();
    }
  }

  /**
   * Handles the "tools/vote" keyboard state
   * @param {JQuery.KeyboardEventBase} e
   */
  function voteMenu(e) {
    if (getModifierState(e)) {
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
  }
});
