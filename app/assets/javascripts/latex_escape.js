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

  ruleset.match.lastIndex = start;
  const match = ruleset.match.exec(state.src);
  if (!match || ruleset.validate && !ruleset.validate(match[0])) { return false; }

  const end = start + match[0].length

  let nextLine = startLine;

  while (nextLine < endLine && state.eMarks[nextLine] != end) {
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
  block_token.content = state.src.substring(start, end);

  state.push('math_close', 'math', -1);

  state.parentType = parentType;
  state.line = nextLine + 1;

  return true;
}

// match: Sticky regex matching the LaTeX
latexEscape.inlineDelimiters = {
  '$': {
    match: /\$.+?\$/y       // $...$
  },
  '\\(': {
    match: /\\\(.+?\\\)/y   // \(...\)
  },
  // Block-level delimiters work inline too!
  '$$': {
    match: /\$\$.+?\$\$/y   // $$...$$
  },
  '\\[': {
    match: /\\\[.+?\\\]/y   // \[...\]
  }
};

// Same format as above
// Note: all regexs *must* end in an end-of-line assertion $
// This is because markdown-it needs blocks to contain full lines.
latexEscape.blockDelimiters = {
  '$$': {
    // $$...$$
    match: /\$\$[^]+?\$\$$/my,
    // Make sure there's no intervening $$
    // Fixes the bug where it would match all of the following 3 lines
    // $$123$$ some text
    //
    // not math $$456$$
    validate: match => match.indexOf('$$', 2) === match.length - 2.
  },
  '\\[': {
    match: /\\\[[^]+?\\\]$/my   // \[...\]
  },
  'begin-end': {
    match: /\\begin\{(.+?)\}[^]+?\\end\{\1\}$/my // \begin{...}...\end{...}
  }
}