$(() => {
  const stringInsert = (str, idx, insert) => str.slice(0, idx) + insert + str.slice(idx);

  const insertIntoField = ($field, start, end) => {
    let value = $field.val();
    value = stringInsert(value, $field[0].selectionStart, start);
    if (end) {
      value = stringInsert(value, $field[0].selectionEnd + start.length, end);
    }
    $field.val(value).trigger('markdown');
  };

  const replaceSelection = ($field, text) => {
    const prev = $field.val();
    $field.val(prev.substring(0, $field[0].selectionStart) + text + prev.substring($field[0].selectionEnd));
  };

  $(document).on('click', '.js-markdown-tool', ev => {
    const $tgt = $(ev.target);
    const $button = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const action = $button.attr('data-action');
    const $field = $('.js-post-field');

    const actions = {
      bold: ['**', '**'],
      italic: ['_', '_'],
      code: ['`', '`'],
      quote: ['\n > ', null],
      bullet: ['\n * ', null],
      numbered: ['\n 1. ', null],
      heading: ['\n# ', null],
      hr: ['\n\n-----\n\n', null],
      table: ['\n\n| Title1 | Title2 |\n|- | - |\n| row1_1 | row1_2 |\n\n', null]
    };

    if (Object.keys(actions).indexOf(action) !== -1) {
      const preSelection = [$field[0].selectionStart, $field[0].selectionEnd];
      insertIntoField($field, actions[action][0], actions[action][1]);
      $field.focus();
      $field[0].selectionStart = preSelection[0] + actions[action][0].length;
      $field[0].selectionEnd = preSelection[1] + actions[action][0].length;
    }
  });

  $('#markdown-link-name, #markdown-link-url').on('keydown', ev => {
    if (ev.keyCode === 13) {
      // don't submit post form on enter in link modal
      ev.stopPropagation();
    }
  });

  $('.js-post-field').on('keydown', ev => {
    if (ev.ctrlKey) {
      switch (ev.keyCode) {
        case 66:
          $('[data-action="bold"]').click();
          break;
        
        case 73:
          $('[data-action="italic"]').click();
          break;

        case 75:
          ev.preventDefault();
          $('[data-modal="#markdown-link-insert"]').click();
          break;

        case 80:
          ev.preventDefault();
          $('[data-action="code"]').click();
          break;

        case 81:
          $('[data-action="quote"]').click();
          break;

        case 85:
          ev.preventDefault();
          $('[data-modal="#markdown-image-upload"]').click();
          break;
      }
    }
  });

  $(document).on('click', '.js-markdown-insert-link', ev => {
    ev.preventDefault();

    const $tgt = $(ev.target);
    const $name = $('#markdown-link-name');
    const text = $name.val();
    const $url = $('#markdown-link-url');
    const url = $url.val();
    const markdown = `[${text}](${url})`;
    const $field = $('.js-post-field');

    if ($field[0].selectionStart != null && $field[0].selectionStart !== $field[0].selectionEnd) {
      replaceSelection($field, markdown);
    }
    else {
      insertIntoField($field, markdown);
    }

    $field.trigger('markdown');
    $tgt.parents('.modal').removeClass('is-active');
    $name.val('');
    $url.val('');
  });

  $(document).on('click', '[data-modal="#markdown-link-insert"]', ev => {
    const $field = $('.js-post-field');
    const selection = $field.val().substring($field[0].selectionStart, $field[0].selectionEnd);
    if (selection) {
      $('#markdown-link-name').val(selection);
    }
    $('#markdown-link-url').focus();
  });

  QPixel.addPrePostValidation(text => {
    // This regex catches Markdown images with no or default alt text.
    const altRegex = /!\[(?:Image alt text)?\](?:\(.+(?!\\\))\)|\[.+(?!\\\])\])/gi;
    if (text.match(altRegex)) {
      const message = `It looks like you're posting an image with no alt text. Alt text is important for ` +
                      `accessibility. Consider adding alt text to the images in your post - ` +
                      `<a href="/help/alt-text">read this help article</a> for details and help writing alt text.`;
      return [false, [{ type: 'warning', message }]];
    }
    else {
      return [true, null];
    }
  });
});
