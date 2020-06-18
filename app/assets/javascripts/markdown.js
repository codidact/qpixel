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
      hr: ['\n\n-----\n\n', null]
    };

    if (Object.keys(actions).indexOf(action) !== -1) {
      const preSelection = [$field[0].selectionStart, $field[0].selectionEnd];
      insertIntoField($field, actions[action][0], actions[action][1]);
      $field.focus();
      $field[0].selectionStart = preSelection[0] + actions[action][0].length;
      $field[0].selectionEnd = preSelection[1] + actions[action][0].length;
    }
  });

  $(document).on('click', '.js-markdown-insert-link', ev => {
    ev.preventDefault();
    const $tgt = $(ev.target);
    const text = $('#markdown-link-name').val();
    const url = $('#markdown-link-url').val();
    const markdown = `[${text}](${url})`;
    insertIntoField($('.js-post-field'), markdown);
    $tgt.parents('.modal').removeClass('is-active');
  });
});