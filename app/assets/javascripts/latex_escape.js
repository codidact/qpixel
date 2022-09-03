// markdown-it plugin to escape LaTeX

function latexEscape(md, options) {
  // Load all the rules
  for (const [rule, ruleset] of Object.entries(latexEscape.inlineDelimiters)) {
    md.inline.ruler.before('escape', rule, latexEscape.inlineRule(ruleset));
  }

  for (const [rule, ruleset] of Object.entries(latexEscape.blockDelimiters)) {
    md.block.ruler.before('fence', rule, latexEscape.blockRule(ruleset));
  }

  // We just need to escape it for the MathJax parser,
  // so we can just return the contents as-is
  md.renderer.rules['inline_math'] =
    md.renderer.rules['block_math'] =
    md.renderer.rules['math_open'] =
    md.renderer.rules['math_close'] = (tokens, idx) => tokens[idx].content;
}

latexEscape.inlineRule = ruleset => (state, silent) => {
  const start = state.pos;

  ruleset.match.lastIndex = start;
  const match = ruleset.match.exec(state.src);
  if (!match) { return false; }

  const end = start + match[0].length

  if (!silent) {
    const token = state.push('inline_math', 'math', 0);
    token.content = state.src.substring(start, end);
  }

  state.pos = end;

  return true;
}

latexEscape.blockRule = ruleset => (state, startLine, endLine, silent) => {
  const start = state.bMarks[startLine] + state.tShift[startLine]

  if (!state.src.startsWith(ruleset.open, start)) { return false; }

  let nextLine = startLine + 1;

  while (nextLine < endLine && !state.src.endsWith(ruleset.close, state.eMarks[nextLine])) {
    ++nextLine;
  }

  // no ending found
  if (nextLine === endLine) {
    return false;
  }
  const parentType = state.parentType;

  state.push('math_open', 'math', 1);

  state.parentType = 'math';

  const block_token = state.push('block_math', 'math', 0)
  block_token.content = state.src.substring(start, state.eMarks[nextLine]);

  state.push('math_close', 'math', -1);

  state.parentType = parentType;
  state.line = nextLine + 1;

  return true;
}

// match: Sticky regex matching the LaTeX
latexEscape.inlineDelimiters = {
  '$': {
    match: /\$.+\$/y       // $...$
  },
  '\\(': {
    match: /\\\(.+\\\)/y   // \(...\)
  },
  // Block-level delimiters work inline too!
  '$$': {
    match: /\$\$.+\$\$/y   // $$...$$
  },
  '\\[': {
    match: /\\\[.+\\\]/y   // \[...\]
  }
};

// Similar format to the above
// Regexes aren't really necessary, since blocks can only match whole lines anyway
latexEscape.blockDelimiters = {
  '$$': {
    open: '$$',
    close: '$$',
  },
  '\\[': {
    open: '\\[',
    close: '\\]',
  }
}