# QPixel [![CircleCI Build Status](https://circleci.com/gh/ArtOfCode-/qpixel.svg?style=svg)](https://circleci.com/gh/ArtOfCode-/qpixel) [![CodeClimate maintainability report](https://codeclimate.com/github/ArtOfCode-/qpixel/badges/gpa.svg)](https://codeclimate.com/github/ArtOfCode-/qpixel) [![Test coverage](https://coveralls.io/repos/github/ArtOfCode-/qpixel/badge.svg?branch=master)](https://coveralls.io/github/ArtOfCode-/qpixel?branch=master)
Rails Q&A software.

## Installation
These instructions are assuming you already have a Unix environment available with Ruby and Bundler installed. WSL should work as well, but Windows is unlikely to.

If you don't already have Ruby installed, use [RVM](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv#installation) to install it before following these instructions.

### Install prerequisites:

    sudo apt update
    sudo apt install gcc
    sudo apt install make
    sudo apt install libmysqlclient-dev
    sudo apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev mailutils
    sudo apt install mutt
    sudo apt install mysql-server
    
### Install JS runtime
If you already have Node.JS installed, you can skip this step. If not, [download and install it](https://nodejs.org/en/download/).
    
### Download QPixel
Clone the repository and `cd` into the directory:

    git clone https://github.com/codidact/qpixel
    cd qpixel

### Configure database connection
If you weren't asked to set the root MySQL user password during `mysql-server` installation, the installation is likely to be using Unix authentication instead. You'll need to log into the MySQL server with `sudo mysql -u root` and create a new database user for QPixel:

```sql
CREATE USER qpixel@localhost IDENTIFIED BY 'choose_a_password_here';
GRANT ALL ON qpixel_dev.* TO qpixel@localhost;
GRANT ALL ON qpixel_test.* TO qpixel@localhost;
GRANT ALL ON qpixel.* TO qpixel@localhost;
```

Copy `config/database.sample.yml` to `config/database.yml` and fill in the correct host, username, and password for your environment. If you've followed these instructions (i.e. you have installed MySQL locally), the correct host is `localhost` or `127.0.0.1`.

### Set up QPixel
Install gems:

    bundle install
    
Set up the database:

    rails db:create
    rails db:schema:load
    rails db:migrate
    rails db:seed

Run the server!

    rails s

You can create the first user account in the application, which should be running at http://localhost:3000/. To upgrade the user account to an admin account, run `rails c` followed by `User.last.update(is_global_admin: true)`.

## License
[MIT licensed](https://github.com/ArtOfCode-/qpixel/blob/master/LICENSE)

## Contributing
Contributions are welcome - please open an issue first for major changes, so that we can discuss what you're working on.
