window.QPixel = window.QPixel || {};

QPixel.MD = {
  insertIntoField($field, start, end) {
    let value = $field.val();

    value = QPixel.MD.stringInsert(value, $field[0].selectionStart, start);

    if (end) {
      value = QPixel.MD.stringInsert(value, $field[0].selectionEnd + start.length, end);
    }

    $field.val(value).trigger('markdown');
  },

  stringInsert: (str, idx, insert) => {
    return str.slice(0, idx) + insert + str.slice(idx);
  },

  stripMarkdown: (content, options = {}) => {
    const stripped = content
      .replace(/(?:^#+ +|^-{3,}|^\[[^\]]+\]: ?.+$|^!\[[^\]]+\](?:\([^)]+\)|\[[^\]]+\])$|<[^>]+>)/g, '')
      .replace(/[*_~]+/g, '')
      .replace(/!?\[([^\]]+)\](?:\([^)]+\)|\[[^\]]+\])/g, '$1');

    if (options.removeLeadingQuote ?? false) {
      return stripped.replace(/^>.+?$/g, '');
    }

    return stripped;
  },
};
