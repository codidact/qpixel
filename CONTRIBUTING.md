# Contributing
Contributing to QPixel follows broadly the same process as any other Codidact project.

## What needs doing?
 - Most bugs and change requests are here on GitHub. Have a look at the open issues to find something that needs doing.
 - There are a few other items in the [TODO list in the wiki](https://github.com/codidact/qpixel/wiki/TODO-list).
   
Once you've picked what you're going to work on, please **leave a comment** on the issue to indicate you're planning to work on
it; this helps us reduce wasted effort. If there's not already an issue for the feature you want to work on, please create one.
If you need time to work on an issue, that's absolutely fine, but please **keep us updated** with comments on the issue - if we
don't hear from you for a few weeks, we may assume you've given up working on that issue and give it to someone else.

## What's the workflow?
 * First, **you need an issue to work under**. Either pick an existing issue or create a new one, and leave a comment on it
   to indicate that you're working on it.
 * Second, you can make your changes. If you have write access to the repository, create a topic branch (please use the format
   `art/40/add-bells-and-whistles`, i.e. `username/issue-number/brief-description`) and make your changes there; if not, fork
   the repository and work in your fork.
 * Once you've made your changes, submit a pull request targeting the `develop` branch.

Keep in mind that **status checks are required to pass** and **at least one approving review** is required from the team before
any pull request can be merged. If status checks don't pass, we won't be able to merge - there are no exceptions, so please fix
the failures and commit again. You can always mark your pull request as a draft while you're still trying to make it work.

## What standards are there?
We have code style and standards documents for each applicable language. Please make sure you follow these if possible; if
there's a good reason why not, please document it in your code, add a linter exception, and let us know why in your pull
request. Here they are:

 * [Code standards: CSS](https://github.com/codidact/core/wiki/Code-standards:-CSS)
 * [Code standards: CSS naming](https://github.com/codidact/core/wiki/Code-standards:-CSS-naming)
 * [Code standards: HTML](https://github.com/codidact/core/wiki/Code-standards:-HTML)
 * [Code standards: JS](https://github.com/codidact/core/wiki/Code-standards:-JS)
 * There is a .rubocop.yml file provided in the project and rubocop is included in the bundle; please run `bundle exec rubocop` for 
   Ruby style checking.
 
When writing CSS, keep in mind that our design framework, [Co-Design](https://design.codidact.org/) is available in QPixel, and
should be used where possible. Avoid writing custom CSS if you can; favour using components and atomic classes from Co-Design.

We also have some [guidelines for commit messages](https://github.com/codidact/core/wiki/Committing-guidelines). Again, please
follow these where possible, as they help us to keep a cohesive commit history and see how the project has developed.
