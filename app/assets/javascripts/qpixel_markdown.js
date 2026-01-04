window.QPixel = window.QPixel || {};

QPixel.MD = {
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
