# QPixel [![CircleCI Build Status](https://circleci.com/gh/codidact/qpixel.svg?style=svg)](https://circleci.com/gh/codidact/qpixel) [![Test coverage](https://coveralls.io/repos/github/ArtOfCode-/qpixel/badge.svg?branch=master)](https://coveralls.io/github/ArtOfCode-/qpixel?branch=master)
Rails-based version of our core software. Currently under active development towards MVP.

## Installation for development
The usual sort of thing. You'll need at least Ruby 2.3, preferably higher. You'll also need MySQL/MariaDB installed. Then:

 * Clone the repo and `cd` into the directory
 * `cp config/database.sample.yml config/database.yml` and fill in `config/database.yml` with the correct values for your environment
 * Run `bundle install`
 * Run `rails db:setup` and `rails db:migrate`
 * Run `rails s`

## License
[AGPL licensed](https://github.com/codidact/qpixel/blob/master/LICENSE)

## Contributing
Contributions are welcome - please read the [CONTRIBUTING](https://github.com/codidact/qpixel/blob/develop/CONTRIBUTING.md) document
before you start and look at the [TODO list](https://github.com/codidact/qpixel/wiki/TODO-list) for things to do.
