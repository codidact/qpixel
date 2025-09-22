window.QPixel = window.QPixel || {};

QPixel.MD = {
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
