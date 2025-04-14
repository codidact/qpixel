# Contributing
Contributing to QPixel follows broadly the same process as any other Codidact project.

## What needs doing?
- We have a [roadmap](https://github.com/orgs/codidact/projects/6) which lists broad priorities and contains issues
  which fall into each priority. Issue labels provide more information about what area, language, and difficulty each
  issue involves.
- Most bugs and change requests are [here on GitHub](https://github.com/codidact/qpixel/issues). Have a look at all
  open issues (additionally to the roadmap) to find something that needs doing.
- Additional information may be found in the [feature request](https://meta.codidact.com/categories/3/tags/961) and
  [bug](https://meta.codidact.com/categories/3/tags/394) tags of Codidact Meta

Once you've picked what you're going to work on, please **leave a comment** on the issue to indicate you're planning
to work on it; this helps us reduce wasted effort. If there's not already an issue for the feature you want to work
on, please create one. If you need time to work on an issue, that's absolutely fine, but please **keep us updated**
with comments on the issue - if we don't hear from you for a few weeks, we may assume you've given up working on that
issue and give it to someone else.

## What's the workflow?
- First, **you need an issue to work under**. Either pick an existing issue or create a new one, and leave a comment
  on it to indicate that you're working on it.
- Second, you can make your changes. If you have write access to the repository, create a topic branch (please use
  the format `art/40/add-bells-and-whistles`, i.e. `username/issue-number/brief-description`) and make your changes
  there; if not, fork the repository and work in your fork.
- Once you've made your changes, submit a pull request targeting the `develop` branch.

Keep in mind that **status checks are required to pass** and **at least one approving review** is required from the
team before any pull request can be merged. If status checks don't pass, we won't be able to merge. You can always mark
your pull request as a draft while you're still trying to make it work.

## What guidelines are there?
When developing, please bear the following in mind:

* **Avoid jQuery**. We are moving the project away from jQuery; some critical dependencies remain
  which mean we haven't yet been able to remove it, but new code should use vanilla JS wherever practical.
* **Follow existing styles**. Your code should be in line with the code style used throughout the project. Rubocop is
  provided for Ruby code and your code should pass it. There is no linter for JS but style will be manually checked when
  your pull request is reviewed.
* **Test your code**. You should both test manually by trying any new/changed/updated functionality, and include 
  automated tests with your PR. All tests must pass before your PR can be accepted. There is an automated status check
  for pull requests which will fail if your code is not sufficiently covered by tests.
* **Develop for accessibility**. Particularly when changing front-end code, develop with accessibility as a primary
  concern. Content should adhere to WCAG wherever possible. This extends to your code as well - write code that is
  accessible and clear for developers who come after you, including comments where necessary.

Detailed style guidance for each language is available [here](CODE-STANDARDS.md).

Developer documentation for the QPixel internal API is available [here](https://docs.dev.codidact.org/).

If you're in doubt about how to approach or design something, leave a comment on the issue so that we can discuss your
proposed changes - we'd rather have a discussion first than have to reject hard work you've already done.

## Be nice; be respectful
Always be constructive, especially when giving feedback. Always presume that others are acting with good intent.
Contributors and contributions must abide by the
[Codidact Code of Conduct](https://github.com/codidact/qpixel?tab=coc-ov-file#readme).
