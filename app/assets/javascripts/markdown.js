$(() => {
  /** @implements {MarkdownAction} */
  class InlineAction {
    constructor(start, end = '') {
      this.start = start;
      this.end = end;
    }

    /**
     * @param {JQuery<HTMLTextAreaElement | HTMLInputElement>} $field 
     */
    apply($field) {
      const preSelectionStart = $field[0].selectionStart;
      const preSelectionEnd = $field[0].selectionEnd;
      QPixel.MD.insertIntoField($field, this.start, this.end);
      $field[0].selectionStart = preSelectionStart + this.start.length;
      $field[0].selectionEnd = preSelectionEnd + this.end.length;
    }
  }

  /** @implements {MarkdownAction} */
  class BlockAction {
    /**
     * @param {function(string, number): string} callback
     * @param {boolean} skip_blanks
     */
    constructor(callback, skip_blanks) {
      this.callback = callback;
      this.skip_blanks = skip_blanks;
    }

    /**
     * @param {JQuery<HTMLTextAreaElement | HTMLInputElement>} $field 
     */
    apply($field) {
      // Override the selection range so it encompasses full lines
      const [startPos, endPos] = this.#getBlockSelection($field);
      $field[0].setSelectionRange(startPos, endPos);
      const lines = $field.val().substring(startPos, endPos).split('\n');
      let jdx = 0;
      for (let idx = 0; idx < lines.length; ++idx) {
        if (lines[idx] != '' || !this.skip_blanks) {
          lines[idx] = this.callback(lines[idx], jdx);
          ++jdx;
        }
      }
      $field[0].setRangeText(lines.join('\n'));
    }


    /**
     * @param {JQuery<HTMLTextAreaElement | HTMLInputElement>} $field 
     * @returns {[number, number]} 
     */
    #getBlockSelection($field) {
      const preSelectionStart = $field[0].selectionStart;
      const preSelectionEnd = $field[0].selectionEnd;
      const val = $field.val();
      // Not particularly efficient, but seems to work fine
      let startPos, endPos;
      let idx = 0;
      for (const line of val.split('\n')) {
        const begin = idx;
        const end = begin + line.length;
        if (begin <= preSelectionStart && preSelectionStart <= end) {
          startPos = begin;
        }
        if (begin <= preSelectionEnd && preSelectionEnd <= end) {
          endPos = end;
        }
        // include newline
        idx = end + 1;
      }
      return [startPos, endPos];
    }
  }

  /**
   * @type {{[key: string]: MarkdownAction}}
   */
  const actions = {
    bold: new InlineAction('**', '**'),
    italic: new InlineAction('_', '_'),
    code: new InlineAction('`', '`'),
    quote: new BlockAction(l => `> ${l}`, false),
    bullet: new BlockAction(l => `* ${l}`, true),
    numbered: new BlockAction((l, i) => `${i + 1}. ${l}`, true),
    heading: new BlockAction(l => `# ${l}`, true),
    hr: new InlineAction('\n\n-----\n\n'),
    table: new InlineAction('\n\n| Title1 | Title2 |\n|- | - |\n| row1_1 | row1_2 |\n\n'),
    mathjax: new InlineAction('$', '$'),
  };

  $(document).on('click', '.js-markdown-tool', (ev) => {
    const $tgt = $(ev.target);
    const $button = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const action = $button.attr('data-action');

    /** @type {JQuery<HTMLTextAreaElement | HTMLInputElement>} */
    const $field = $('.js-post-field');

    if (action && action in actions) {
      actions[action].apply($field);
      $field.trigger("focus");
    }
  });

  QPixel.DOM?.addSelectorListener('keypress', '#markdown-link-name, #markdown-link-url', (ev) => {
    if (ev instanceof KeyboardEvent && ev.key === 'Enter') {
      ev.preventDefault();
    }
  });

  $('.js-post-field').on('keydown', (ev) => {
    if (ev.ctrlKey && !ev.shiftKey && !ev.altKey) {
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

  $(document).on('click', '.js-markdown-insert-link', (ev) => {
    ev.preventDefault();

    const $tgt = $(ev.target);
    const $name = $('#markdown-link-name');
    const text = $name.val();
    const $url = $('#markdown-link-url');
    const url = $url.val();
    const markdown = `[${text}](${url})`;

    /** @type {JQuery<HTMLTextAreaElement | HTMLInputElement>} */
    const $field = $('.js-post-field');

    if ($field[0].selectionStart != null && $field[0].selectionStart !== $field[0].selectionEnd) {
      QPixel.MD.replaceSelection($field, markdown);
    }
    else {
      QPixel.MD.insertIntoField($field, markdown);
    }

    $field.trigger('markdown');
    $tgt.parents('.modal').removeClass('is-active');
    $name.val('');
    $url.val('');
  });

  $(document).on('click', '[data-modal="#markdown-link-insert"]', (_ev) => {
    /** @type {JQuery<HTMLTextAreaElement | HTMLInputElement>} */
    const $field = $('.js-post-field');

    const selection = $field.val().substring($field[0].selectionStart, $field[0].selectionEnd);
    if (selection) {
      $('#markdown-link-name').val(selection);
    }
    $('#markdown-link-url').focus();
  });

  QPixel.addPrePostValidation((text) => {
    // catch Markdown images with no or default alt text: https://regex101.com/r/ubcVn4/2
    const altRegex = /!\[(?:Image_alt_text)?\](?:\([^\)]+?\)|\[.+(?!\\\])\])/gi;
    if (text.match(altRegex)) {
      const message =
        `It looks like you're posting an image with no alt text. Alt text is important for ` +
        `accessibility. Consider adding alt text to the images in your post - ` +
        `<a href="/help/alt-text">read this help article</a> for details and help writing alt text.`;
      return [false, [{ type: 'warning', message }]];
    }
    else {
      return [true, null];
    }
  });
});
