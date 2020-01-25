# QPixel [![CircleCI Build Status](https://circleci.com/gh/ArtOfCode-/qpixel.svg?style=svg)](https://circleci.com/gh/ArtOfCode-/qpixel) [![CodeClimate maintainability report](https://codeclimate.com/github/ArtOfCode-/qpixel/badges/gpa.svg)](https://codeclimate.com/github/ArtOfCode-/qpixel) [![Test coverage](https://coveralls.io/repos/github/ArtOfCode-/qpixel/badge.svg?branch=master)](https://coveralls.io/github/ArtOfCode-/qpixel?branch=master)
Rails Q&A software.

## Installation
The usual sort of thing:

 * Clone the repo and `cd` into the directory
 * Fill in `config/database.yml` with the correct values for your environment
 * Run `bundle install`
 * Run `rails db:setup` and `rails db:migrate`
 * Run `rails s`
 
To grant admin/moderator rights to a user, you need to manually update the user account. Run `rails c` for a console, then the following:

```ruby
User.find(USER_ID_HERE).update(is_admin: true, is_moderator: true)  # pick admin and/or moderator as required
```

## License
[MIT licensed](https://github.com/ArtOfCode-/qpixel/blob/master/LICENSE)

## Contributing
Contributions are welcome - please open an issue first for major changes, so that we can discuss what you're working on.
