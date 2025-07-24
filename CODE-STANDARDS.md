# Code Standards

## Ruby

For Ruby style guidance see the [style guide](https://codidact.atlassian.net/wiki/spaces/OPS/pages/766803969/Style+guide+Ruby)
in Confluence (or [public mirror](https://github.com/codidact/docs/blob/master/Developer-Docs/code-style-guides.pdf) in
our docs repository).

## CSS

When writing CSS, keep in mind that our design framework, [Co-Design](https://design.codidact.org/) is available
in QPixel, and should be used where possible. Avoid writing custom CSS if you can; favour using components and
atomic classes from Co-Design.

### Preprocessor
We use SCSS to compile CSS. The source files should be structured like this:

- **Primary files** are standalone and have a filename consisting of one (generally preferable) or multiple words
  (if appropriate - separated by hyphens), ending with the ".scss" file extension.  
  Examples: `codidact.scss`, `material-design-lite-grid.scss`.
- **Secondary files** are included in primary files and cannot exist on their own. Their filename starts with an
  underscore, and then follow the same rules as primary files: one or more words (separated by hyphens), ending with
  the extension ".scss".  
  Examples: `_question-list.scss`, `_icon-toggle.scss`.

Primary files must not be included in other primary or secondary files.

Variables are SCSS variables (evaluated at compile time), unless they are community-specific (such as primary color).
These are CSS variables (`--name`, `var(--name)`) and evaluated at run time.

CSS must be minified after compilation. (TODO: *node-sass has the `--output-style compressed` option, right?)

### Naming

Codidact CSS uses atomic classes and components.

#### Atomic classes

Atomic classes are named with `.has-[Property]-[Value]`. Property names are either single words or multiple,
separated by a dash ("-"). They override a specific property with a specific value.

**Examples:**

```css
.has-color-red
.has-font-size-5
.has-display-none
```

Modifiers (e.g. class is only applied on mobile) are specified by adding `__[Modifier]` to the default class name.

**Examples:**

```css
.has-font-size-5__sm
.has-display-none__lg
```

There are these modifiers:

- `sm` - small screens only (32rem)
- `md` - medium screens only (56rem)
- `lg` - large screens only (72rem)
- `h` - only on hover

#### Components

**Components** are complex and repetitive design parts, designed to solve a specific problem. A component can
consist of one or multiple **elements**, which must not exist outside the component. A component and all it's
elements can be modified using **modifiers**.

Components' names follow this pattern: `.[Component]`. If a component's name consists of more than one word
(e.g. `button list`), it's words should be separated with dashes ("-").

**Examples:**

```css
.modal
.alert
.button-list
```

#### Elements

Elements' names follow this pattern: `.[Component]--[Element]`. If an element's name consists of more than one
word (e.g. `close button`), it's words should be separated with dashes ("-").

**Examples:**

```css
.modal--header
.modal--footer
.modal--close-button
.button-list--item
```

#### Modifiers

Components and elements can be modified *only* using modifiers. They follow this pattern: `.is-[Modifier]`

**Examples:**

```css
.alert.is-danger
.modal.is-with-backdrop
.button.is-active
```

### Order of selectors
Universal [selectors](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors) must appear first, followed by
type (tag) selectors. An extra blank line should separate these from class, attribute and ID selectors, which in turn
can appear in any order.

Selectors (and rules in general) should preferably be added to the CSS stylesheets in the same order in which they
appear in the markup files (`.html`, `.cshtml` and equivalent).

Within stylesheets, the order of selectors should be consistent (i.e. in the global scope as well as within `@media`
selectors).

Pseudo-classes and pseudo-element selectors should appear *after* the main selector if it exists.

`@media` and other nested [*at-rules*](https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule) should be added to
the end of the document, preceded by an extra blank line.

See [*landing-page/dist/assets/css/primary.css @1ca2f671*](https://github.com/codidact/landing-page/blob/1ca2f671/dist/assets/css/primary.css)
for an example of all of the above.

### Spacing
- Code should be indented with four spaces. Do not use tab stops.
- Rules must be separated by a blank line between them.
- Do not write more than one statement per line.

### Line breaks
Rules should be separated by a blank line, except for the two special cases provided in
[Order of selectors](#order-of-selectors) - namely, an extra blank line is expected between universal selectors and
other selectors, as well as before nested _at-rules_. As such, these rule groups should be separated by *two* spaces.

All properties are written on their own line and end with a semicolon. The closing bracket must appear in its own
line.

When multiple selectors are part of the same rule, each selector must appear in a separate line and must be
followed by a comma, except for the last selector which shall contain the opening bracket (`{`) for the CSS rule
as usual.

```css
.red, 
.has-color-red,
.this-color-is-really-red {
    color: #f00;
}
```

An exception is applied: For the combination of a single CSS selector and a single property, the entire rule *can*
(but does not *must*) be written in one line, with spaces surrounding the property within braces:

```css
#load-overlay { display: none; }
```

Comments must be preceded by a newline, but need not be followed by one.

### Shorthand properties
Do not use shorthand properties.  
Prefer:

```css
font-style: bold;
font-size: 2em;
font-family: "Verdana", "Arial", sans-serif;
```

over `font: bold 2em "Verdana", "Arial", sans-serif;`.

### Quotes
Always prefer double quotes.

Always enclose non-generic typeface identifiers in quotes. Generic font-family identifiers must *not* be enclosed
in quotes, according to the [relevant W3C rule](https://www.w3.org/TR/2018/REC-css-fonts-3-20180920/#generic-family-value).
Example:

```css
font-family: "Open Sans", "Helvetica Neue", "Helvetica", "Arial", sans-serif;
```

### Line length
Please limit line length to 120 characters or less.  
Note: this rule is not enforced for arguments to `url()` and other possible corner cases where developers have no
control over the length of arguments.

### Color codes
The preferred syntax for specifying colors is hexadecimal, lowercase, shortened (when possible). `rgba()` syntax is
allowed where transparency is a requirement.

```css
.demo {
    /* these are OK */
    color: #f00;
    background-color: #2d3436;
    box-shadow: 0 14px 14px rgba(0, 0, 0, 0.16);

    /* these are non conforming */
    color: #ff0000; /* should be #f00 */
    color: red; /* should be #f00 */
    background-color: rgb(45, 52, 54); /* should be #2d3436 */
}
```
## HTML

For HTML style guidance see the [style guide](https://codidact.atlassian.net/wiki/spaces/OPS/pages/767295490)
in Confluence (or [public mirror](https://github.com/codidact/docs/blob/master/Developer-Docs/code-style-guides.pdf) in
our docs repository).

## JavaScript

The following is our style guide for writing JavaScript. All JS contributions MUST adhere to this document unless
there's a good reason not to; such reasons MUST have a linter ignore applied to them, and SHOULD be documented using
a comment above the relevant code.

This guide uses [RFC 2119](http://tools.ietf.org/html/rfc2119) terminology.

### Encoding
Use UTF8 encoding, without BOM. Ensure your editor is set to use UTF8 w/o BOM.

### Language Version
Use features of ES6 or above where they are available. Prefer modern constructs over equivalents from previous
language versions. Code will be transpiled to ES5 for builds, so we can use modern features without worrying about
browser compatibility. Particularly:

- Use `const`, not `var`. Use `let` if your variable will be re-assigned.
- Use arrow functions, `() => {}`, where possible. Only use `function` if a `this` context is necessary.
- Use `async`/`await`, not callbacks or `Promise`. Only use a callback when calling an API that does not offer
  `async`.

#### Modules
Write code in ES6 modules. Group related functionality (such as code relating to posts routes) into a single file;
split it into multiple files if the file becomes excessively long. Use `import`/`export` to reference code from
other files.

#### Naming
Name all variables and methods using `lowerCamelCase`. `SHOUTY_CASE` may be used for constants (true constants
only, not just all `const` variables).

Name files in `lisp-case`, using a `.js` extension: `mod-dashboard.js`.

#### Spacing
- Indent code by four spaces. Do not use tab stops.
- Always use a space on both sides of an operator, including in assignments and declarations:
  `1 + 1`, `const foo = 'bar';`, `() => {}`.
- Use a space between parameters in function declarations and calls:
  `(foo, bar) => { }`, `sendFormData(form, 'POST')`.
- Use a space between key and value when declaring object literals, and between each pair:
  `const data = {a: 1, b: 2};`
- Use a space between control flow keywords and the opening parenthesis; as well as between the closing
  parenthesis and the opening brace: `if (x === 1) {`.
- Do not use a space between function definitions or function calls and the opening parenthesis:
  `function getUsersByGroup(groupId)`; `let users = getUsersByGroup(1)`.
- Do not use spaces inside parentheses: `(x === 1)`, _not_ `( x === 1 )`
- Do not write more than one statement per line.

#### Required optional elements
- Semicolons must not be omitted at the end of statements.
- Braces must not be omitted for single-line statements following a control flow expression
  (e.g. `if`/`else`, `for`, `while`).
- Equality checks must use strict equality checking (`===`). The only exception is when checking for null/undefined
values, which may be written as `if (value == null)`.

#### Quotes
Prefer double quotes. If a quoted string contains a literal double quote character, use single quotes instead:

```js
const mergeTargetModal = document.querySelector("#js-merge-target-select");
const groupLinks = document.querySelectorAll('[data-type="type_group"] > a');
```

Use of [template literals](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals) is
allowed where it makes sense.

#### Line length
Do not write lines longer than 120 characters. Lines that would be longer than 120 characters must be hard-wrapped
onto the next line, and every continuation line must be indented _at least_ one more level than the first line.
Wrapped lines may be indented further to align certain elements with one another.

```js
codidact.createDangerConfirmationAudit(document.querySelectorAll('.modal.is-danger > .modal--body'),
                                       'POST', 'https://codidact.org/audits/danger-confirmation');
```

#### Bracing
Follow the K&R style of bracing:

- No line break before opening brace
- Line break after opening brace
- Line break before closing brace
- Line break after closing brace

A blank line must also be added after a closing brace where the brace closes a function, method, or class body.

```js
class ModalDialog {
    constructor(data) {
        if (Object.keys(data).length > 0) {
            this.dataset = data;
        }
        else {
            this.dataset = {};
        }
    }

    get name() {
        return this.dataset['name'] || '(none)';
    }
}
```

#### Conditional assignment
When assigning one of two possible values to a variable according to a condition, prefer the ternary operator (`?:`):

```js
this.dataset = (Object.keys(data).length > 0) ? data : {};
```
Note the use of parentheses around the conditional expression - it makes it more obvious at first glance that this
is a conditional statement. **This is a requirement.**

For very long or deeply indented expressions that exceed the [120-char line length limit](#line-length),
use the following line-break and indenting style:

```js
this.dataset = (Object.keys(data).length > 0 && data.includes("email")
                && data["createdAt"] >= someLongDateTimeString)
               ? data
               : {};
```

When assigning to multiple variables according to the same condition, do *not* use a ternary expression. The
`if / else` block should be used instead (remember: [don't repeat yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)).

## Git commit messages

Commit messages are a golden opportunity to give people context on what you are adding to the codebase. These are
some guidelines to make sure everyone is using them consistently. Help us to keep a cohesive commit history and see
how the project has developed.

### Subject line format
Your subject line (the commit _title_) should be a concise **_summary_** of the changes being submitted. Be specific
and precise, and avoid getting into minuteness - additional context, if needed, should be added in the detailed
commit description, not here.

**Please keep the subject line under 70-75 characters**. This encourages conciseness and ensures the summary is
rendered fully in a diverse range of environments.

**Good:**
```
Add the user's fetch information in a global multidimensional array instead of a local one.
```

**Bad:**
```
Fixed scope bugs.
```

### Commit description format
In most cases - except for the most trivial changes, a commit description (or "_body_") is needed in order to provide
additional context (such as _how_ and _why_ a certain change - or set thereof - was implemented). Be descriptive and
provide as much information as required, while also striving to minimize excessive verbosity.

Commit descriptions can have any arbitrary number of lines, within reason - use your best judgment. Does your
description refer only to things that are relevant to the changes being made?

Also note that, unlike the commit summary, there is **no** restriction imposed on the commit description character
length. Here as well, we expect contributors to use their best judgment, by using line breaks and blank lines where
it makes sense.

- **Include relevant information and context where you can**, to allow us to quickly see the purpose of the commit.
  Don't be too verbose - be specific and concise.
- **Write in the infinitive, not in the past** - i.e. write "Add user details to the global scope and fetch on load"
  rather than "Added user details to the global scope and fetched on load"
- The use of standard markdown is allowed, but we **prefer plain text**. Use single quotes to refer to specific
  filenames or code snippets within the commit message (i.e. `404 error page: Fix conflicting 'margin' CSS property for 'body'`).
  If using markdown, refer to a syntax cheatsheet if necessary.
- Use short commit hashes whenever you need to refer to previous commits from your commit message. The short hash
  should preferably have a length of 8; a length of 7 is also acceptable.
  Example: `Complements 17236a81 by adding line break`.  
Note that the GitHub interface will always render commit hashes abbreviated to 7 chars.

If your change is small enough to not have a commit body, i.e. your subject line can describe your changes, then
it's okay to commit without one. If you're making significant changes that require more explanation then you must
include the commit body.

### Single-purpose commits
Each commit you make should do _one_ thing. Try to make sure all changes in the commit are all for the same purpose
- one refactoring, or one feature, etc. If you have more changes to make, split them up into multiple commits.

### Testing your commits
**Commits on development branches** _need not_ pass tests every time. Particularly if you're writing your tests
first and then developing features, it can be helpful to create a commit where tests don't pass.

**Merges and commits to master** _must_ pass the tests every time. The master branch is considered the stable
channel - anything on there should be suitable for production deployment. Commits should generally not be made
directly to master - only organization and repository administrators have the ability to, and should avoid doing
so if at all possible.

[^1]: [Which 'href' value should I use for JavaScript links, '#' or 'javascript:void(0)'?](https://stackoverflow.com/a/134957/3258851)
[^2]: [Prevent href='#' link from changing the URL hash](https://stackoverflow.com/a/20215524/3258851)
