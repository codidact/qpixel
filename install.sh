#!/bin/bash

# -------------------------------------------------------------------------------------------------
# Error codes
# 10 - No valid ruby present, user chose not to install ruby with this script
# 11 - No valid ruby present, installing rbenv failed
# 12 - No valid ruby present, rbenv ruby-build plugin not present or no ruby 3 version selectable
# 13 - No valid ruby present, rbenv installation of ruby 3 failed
# 14 - No valid ruby present, unable to set ruby version using rbenv
# 15 - No valid ruby present, rvm installation of ruby 3 failed
# 16 - No valid ruby present, unable to set ruby version using rvm

# -------------------------------------------------------------------------------------------------
# Helper functions

log() { printf "%b\n" "$*"; }
warn() { log "WARN: $*" >&2 ; }
fail() { fail_with_code 1 "$*" ; }
fail_with_code() { code="$1" ; shift ; log "\nERROR ($code): $*\n" >&2 ; exit "$code" ; }

# Ask the user a yes/no question
ask()
{
  while true; do
    read -p "$* [Y/n] " -r yn
    case "$yn" in
      ("") return 0;;
      y|Y ) return 0;;
      n|N ) return 1;;
      * ) log "Invalid choice";;
    esac
  done
}

# runs the command, outputting it to the console and
_run()
{
  cmd="$*"
  log "$ $cmd"
  $cmd
}

# Print nicely formatted header to a section
# "Leaks" the $_header_text variable for use in the footer.
# @param 1 - The text to display in the header
# @param 2 - The character to use (default -)
_header()
{
  _header_text="$1"
  _header_char="${2:--}"
  log ""
  log " $_header_char$_header_char$_header_char $_header_text $_header_char$_header_char$_header_char"
  log ""
}

# Print nicely formatted footer to a section
# Uses the leaked $_header_text variable to determine length.
_footer()
{
  local sequence
  # shellcheck disable=SC2183
  sequence="$(printf '%*s' "$((${#_header_text} + 8))" | tr ' ' "$_header_char")"
  log ""
  log " $sequence"
  log ""
}

# Parses a YAML file using awk and sed
# Copied from StackOverflow: https://stackoverflow.com/a/21189044/14170691
function parse_yaml {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*'
  local fs
  fs=$(echo @|tr @ '\034')
  # shellcheck disable=SC2086 disable=SC1087
  sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
      printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
  }'
}

# -------------------------------------------------------------------------------------------------
# General

# Asks whether this setup is for production
check_production()
{
  if ask "Are you setting up QPixel for development?"; then
    production=0
    development=1
  else
    production=1
    development=0
  fi
}

# Convenience getters which turn the production / development variables into return values.
# Note that return values (0 = good, 1 = bad) are inverted from boolean values (0 = false, 1 = true)
is_prod() { return $((1 - production)); }
is_dev() { return $((1 - development)); }

# -------------------------------------------------------------------------------------------------
# System packages

# Checks whether nodejs is present and reports that to the user.
# @return 0 if found, 1 otherwise
check_nodejs()
{
  if builtin command -v node > /dev/null; then
    log "✅ NodeJS: found $(node --version)"
  else
    log "❌ NodeJS: not found"
    return 1
  fi
}

# Secures a MySQL installation by having the user set a password and go through the security setup.
secure_mysql()
{
  temp_passwd="$(sudo grep 'temporary password' /var/log/mysqld.log)"
  log "🔶 Packages: Your mysql root password is $temp_passwd"

  # TODO
}

# Detects the package manager(s) present on the system and asks the user to install dependencies
# with all of them.
# In case of rejection for all, we fail.
install_packages()
{
  if ! ask "Do you want to install required system packages?"; then
    log "🔶 Packages: Skipping installation of system packages."
    return 0
  fi

  any_matched=1

  if builtin command -v apt-get > /dev/null; then
    log "Detected apt-get (debian-based)"
    if ask "Do you want to install required packages with apt-get?"; then
      install_packages_apt
      return $?
    else
      any_matched=0
      log "Not installing with apt-get"
    fi
  fi

  if builtin command -v pacman > /dev/null; then
    log "Detected pacman (arch-based)"
    if ask "Do you want to install required packages with pacman?"; then
      install_packages_pacman
      return $?
    else
      any_matched=0
      log "Not installing with pacman"
    fi
  fi
  
  if builtin command -v dnf > /dev/null; then
    log "Detected dnf (fedora-based)"
    if ask "Do you want to install required packages with dnf?"; then
      install_packages_dnf
      return $?
    else
      any_matched=0
      log "Not installing with dnf"
    fi
  fi

  # Homebrew is intentionally placed at the bottom, as it is possible to use homebrew on linux
  # In that case, the user may prefer using their system package manager.
  if builtin command -v brew > /dev/null; then
    log "Detected homebrew"
    if ask "Do you want to install required packages with homebrew?"; then
      install_packages_homebrew
      return $?
    else
      any_matched=0
      log "Not installing with homebrew"
    fi
  fi

  # If we found any package manager, but did not confirm install with any of them, fail.
  if [ $any_matched == 0 ]; then
    fail "❌ No supported package manager was selected. Please install the required packages using the instructions."
  fi
}

install_packages_apt()
{
  _header "UPDATING PACKAGE DATABASE USING APT-GET"
  if ! _run 'sudo apt-get update'; then
    fail "❌ Unable to update package database using apt-get!"
  fi
  _footer

  # Base packages
  _header "INSTALLING BASE PACKAGES USING APT-GET"
  if ! _run 'sudo apt-get -y install gcc make pkg-config autoconf bison build-essential libssl-dev libyaml-dev libreadline-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev libmysqlclient-dev'; then
    fail "❌ Unable to install base packages. Please refer to the error above."
  fi
  if ! _run 'sudo apt-get -y install libvips'; then
    fail "❌ Unable to install libvips. Please refer to the error above."
  fi
  if ! _run 'sudo apt-get -y install libmagickwand-dev'; then
    fail "❌ Unable to install libmagickwand-dev (imagemagick). Please refer to the error above."
  fi
  _footer
  log "✅ Packages: installed base packages"

  if ! check_nodejs && ask "Do you want to install nodejs?"; then
    _header "INSTALLING NODEJS USING APT-GET"
    if ! _run 'sudo apt-get -y install nodejs'; then
      fail "❌ Unable to install nodejs. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed nodejs"
  fi

  log "To run QPixel, you need a database, either MySQL or MariaDB."
  log "You can install either locally (with this install script), run in docker or use a database on another server (you will have to do that yourself)."
  if ask "Do you want to install MySQL?"; then
    _header "INSTALLING MYSQL-SERVER USING APT-GET"
    if ! _run 'sudo apt-get -y install mysql-server'; then
      fail "❌ Unable to install mysql. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mysql"
    secure_mysql
  elif ask "Do you want to install MariaDB?"; then
    _header "INSTALLING MARIADB-SERVER USING APT-GET"
    if ! _run 'sudo apt-get -y install mariadb-server'; then
      fail "❌ Unable to install mariadb. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mariadb"
  else
    log "🔶 Packages: skipped installing database software"
  fi
}

install_packages_pacman()
{
  # Update database
  _header "UPDATING PACKAGE DATABASE USING PACMAN"
  if ! _run 'sudo pacman -Syyu'; then
    fail "❌ Unable to update package database using pacman!"
  fi
  _footer

  # Base packages
  _header "INSTALLING BASE PACKAGES USING PACMAN"
  if ! _run 'sudo pacman -S gcc make autoconf bison base-devel unixodbc openssl'; then
    fail "❌ Unable to install base packages. Please refer to the error above."
  fi
  if ! _run 'sudo pacman -S libvips'; then
    fail "❌ Unable to install libvips. Please refer to the error above."
  fi
  if ! _run 'sudo pacman -S imagemagick'; then
    fail "❌ Unable to install imagemagick. Please refer to the error above."
  fi
  _footer
  log "✅ Packages: installed base packages"

  # NodeJS
  if ! check_nodejs && ask "Do you want to install nodejs?"; then
    _header "INSTALLING NODEJS USING PACMAN"
    if ! _run 'sudo pacman -S nodejs'; then
      fail "❌ Unable to install nodejs. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed nodejs"
  fi

  # MySQL / MariaDB
  log "To run QPixel, you need a database, either MySQL or MariaDB."
  log "You can install either locally (with this install script), run in docker or use a database on another server (you will have to do that yourself)."
  if ask "Do you want to install MySQL?"; then
    _header "INSTALLING MYSQL USING PACMAN"
    if ! _run 'sudo pacman -S mysql'; then
      fail "❌ Unable to install mysql. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mysql"
  elif ask "Do you want to install MariaDB?"; then
    _header "INSTALLING MARIADB USING PACMAN"
    if ! _run 'sudo pacman -S mariadb'; then
      fail "❌ Unable to install mariadb. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mariadb"
  else
    log "🔶 Packages: skipped installing database software"
  fi

  # MySQL-client-headers Arch users should know what they are doing
  log ""
  log "You will need the mysql/mariadb client library files to install the ruby mysql2 gem."
  log "These are present in mariadb-libs and in libmysqlclient"

  if ask "Install mariadb-libs?"; then
    _header "INSTALLING MARIADB-LIBS USING PACMAN"
    if ! _run 'sudo pacman -S mariadb-libs'; then
      fail "❌ Unable to install mariadb-libs. This error may be due to a conflict with MySQL. If you have MySQL installed, you may not need to install this package. In that case, rerun this install script but skip installing packages."
    fi
    _footer
    log "✅ Packages: installed mariadb-libs"
  elif ask "Install libmysqlclient?"; then
    _header "INSTALLING LIBMYSQLCLIENT USING PACMAN"
    if ! _run 'sudo pacman -S libmysqlclient'; then
      fail "❌ Unable to install libmysqlclient. This error may be due to a conflict with MariaDB. If you have MariaDB installed, you may not need to install this package. In that case, rerun this install script but skip installing packages."
    fi
    _footer
    log "✅ Packages: installed libmysqlclient"
  fi
}

install_packages_dnf()
{
  # Update database
  _header "UPDATING PACKAGE DATABASE USING DNF"
  if ! _run 'sudo dnf update'; then
    fail "❌ Unable to update package database using pacman!"
  fi
  _footer

  # Base packages
  _header "INSTALLING BASE PACKAGES USING DNF"
  if ! _run 'sudo dnf group install "C Development Tools and Libraries" -y'; then
    fail "❌ Unable to install group C Development Tools and Libraries. Please refer to the error above."
  fi
  if ! _run 'sudo dnf install ruby-devel zlib-devel -y'; then
    fail "❌ Unable to install ruby-devel and zlib-devel. Please refer to the error above."
  fi
  # Order swapped here as vips is more tricky than imagemagick-libs.
  if ! _run 'sudo dnf install imagemagick-libs -y'; then
    fail "❌ Unable to install imagemagick-libs. Please refer to the error above."
  fi
  if ! _run 'sudo dnf install vips -y'; then
    fail "❌ Unable to install vips. Please refer to the error above.\nNote that on CentOS, vips is not in the default repositories, but can be compiled from source or installed from other repositories (like Remi)."
  fi
  _footer
  log "✅ Packages: installed base packages"

  if ! check_nodejs && ask "Do you want to install nodejs?"; then
    _header "INSTALLING NODEJS USING DNF"
    if ! _run 'sudo dnf install nodejs -y'; then
      fail "❌ Unable to install nodejs. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed nodejs"
  fi

  log "To run QPixel, you need a database, either MySQL or MariaDB."
  log "You can install either locally (with this install script), run in docker or use a database on another server (you will have to do that yourself)."
  if ask "Do you want to install MySQL?"; then
    _header "INSTALLING MYSQL USING DNF"
    if ! _run 'sudo dnf install community-mysql-server community-mysql-libs -y' && ! _run 'sudo dnf install mysql-server mysql-libs -y'; then
      fail "❌ Unable to install mysql. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mysql"
    secure_mysql
  elif ask "Do you want to install MariaDB?"; then
    _header "INSTALLING MARIADB-SERVER USING DNF"
    if ! _run 'sudo dnf install mariadb-server mariadb-connector-c-devel -y'; then
      fail "❌ Unable to install mariadb. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mariadb"
  else
    log "🔶 Packages: skipped installing database software"
  fi
}

install_packages_homebrew()
{
  # Check XCode CLI Tools on Mac
  case "$OSTYPE" in
    darwin*)
      if ! xcode-select -p > /dev/null; then
        log "Detected Mac OS. On Mac, QPixel needs the XCode Command Line Tools."
        if ask "Do you want to install XCode Command Line Tools?"; then
          _header "INSTALLING XCODE CLI TOOLS"
          log "Please confirm the installation using the GUI prompt."
          log ""
          if ! _run 'xcode-select --install'; then
            fail "❌ xcode-select --install failed"
          fi
          _footer
        fi
      fi
      ;;
    *) ;;
  esac

  # Base packages
  _header "INSTALLING PACKAGES USING HOMEBREW"
  if ! _run 'brew install bison openssl mysql-client'; then
    fail "❌ Error while installing packages with brew. Please refer to the error above."
  fi
  if ! _run 'brew install vips'; then
    fail "❌ Error while installing vips with brew. Please refer to the error above."
  fi
  if ! _run 'brew install imagemagick'; then
    fail "❌ Error while installing imagemagick with brew. Please refer to the error above."
  fi
  _footer
  log "✅ Packages: installed base packages"

  if ! check_nodejs && ask "Do you want to install nodejs?"; then
    _header "INSTALLING NODEJS USING HOMEBREW"
    if ! _run 'brew install node'; then
      fail "❌ Unable to install nodejs. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed nodejs"
  fi

  log "To run QPixel, you need a database, either MySQL or MariaDB."
  log "You can install either locally (with this install script), run either in docker or use either on another server (you will have to do that yourself)."
  if ask "Do you want to install MySQL locally?"; then
    _header "INSTALLING MYSQL USING HOMEBREW"
    if ! _run 'brew install mysql'; then
      fail "❌ Unable to install mysql. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mysql"
    secure_mysql
  elif ask "Do you want to install MariaDB locally?"; then
    _header "INSTALLING MARIADB USING HOMEBREW"
    if ! _run 'brew install mariadb'; then
      fail "❌ Unable to install mariadb. Please refer to the error above."
    fi
    _footer
    log "✅ Packages: installed mariadb"
  else
    log "🔶 Packages: skipped installing database software"
  fi
}

# -------------------------------------------------------------------------------------------------
# Ruby

## Asks to install RVM, and if user agrees continues with the installation
#install_rvm()
#{
#  log "We recommend installing Ruby using RVM"
#  if ! ask "Do you want to install RVM now?"; then
#    log "Not installing RVM"
#    return 1
#  fi
#
#  log " --- Installing RVM ---"
#  log "\curl -sSL https://get.rvm.io | bash -s stable --ruby"
#
#  return $?
#}

install_rbenv()
{
  log "We recommend installing ruby using rbenv"
  if ! ask "Do you want to install rbenv?"; then
    fail_with_code 10 "❌ Not installing rbenv. Please install ruby 3.x"
  fi

  _header "INSTALLING RBENV"

  if ! _run '\curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash'; then
    fail_with_code 11 "❌ Something went wrong with the installation. Please refer to output above."
  fi

  log ""
  log " ------------------------"

  log "✅ Ruby - rbenv: installed rbenv"

  log ""
  log "🔶 To finish the setup of rbenv, run the following command and follow its instructions:"
  log ""
  log "  rbenv init"
  log ""
  log "After doing so, please close your terminal and open a new one, then rerun this install command."
  exit 0
}

install_ruby_with_rbenv()
{
  if ! latest_3=$(rbenv install -l | grep "^3\.\d\d*\.\d\d*$" | tail -n1); then
    fail_with_code 12 "
It looks like your rbenv does not have the install option or does not know about any ruby 3 versions.

This may be because you are missing the ruby-build plugin for rbenv. Another potential cause is that your version of rbenv is too old.

Please refer to the documentation of rbenv at https://github.com/rbenv/rbenv to debug this issue.

You can also consider removing rbenv. This install script can re-install it for you."
  fi

  if ! ask "Do you want to install the latest ruby 3.x version using rbenv now?"; then
    fail_with_code 10 "❌ Not installing ruby using rbenv. Please install ruby 3.x"
  fi

  _header "INSTALLING RUBY $latest_3 USING RBENV"

  if ! _run "rbenv install \"$latest_3\""; then
    fail_with_code 13 "Something went wrong with the installation. Please refer to the rbenv output above."
  fi

  _footer

  log "✅ Ruby - rbenv: installed ruby $latest_3"

  if _run "rbenv local \"$latest_3\""; then
    log "✅ Ruby - rbenv: set ruby $latest_3 as default for QPixel"
    log "🔶 Ruby - rbenv: use \`rbenv global $latest_3\` to set your global ruby version."
  else
    log "❌ Ruby - rbenv: unable to set ruby $latest_3 as default for QPixel"
    fail_with_code 14 "Use \`rbenv local $latest_3\` or \`rbenv global $latest_3\` to set your current ruby version."
  fi

  return 0
}

install_ruby_with_rvm()
{
  if ! ask "Do you want to install ruby using RVM now?"; then
    fail_with_code 10 "❌ Not installing ruby using RVM. Please install ruby 3.x"
  fi

  _header "INSTALLING RUBY USING RVM"

  if ! _run 'rvm install ruby --latest'; then
    fail_with_code 15 "Something went wrong with the installation. Please refer to the rvm output above."
  fi

  _footer
  log "✅ Ruby - rvm: installed ruby"

  if _run 'rvm --default use ruby --latest'; then
    log "✅ Ruby - rvm: set installed ruby as default for QPixel"
  else
    log "❌ Ruby - rvm: unable to set installed ruby as default for QPixel"
    fail_with_code 16 "Use \`rvm use ruby --latest\` or \`rvm --default use ruby --latest\` to set your current ruby version."
  fi

  return 0
}

# Checks whether ruby is installed
# If it is not installed (or the installed version is not supported), will ask user to install it
# using rbenv/rvm or install rbenv to do so.
# @return 0 if ruby found, 101 if ruby should be rechecked.
check_install_ruby()
{
  if builtin command -v ruby > /dev/null; then
    # Check whether ruby 3
    rbversion="$(ruby --version)"
    regex="(ruby 3\.[0-9]+\.[0-9]+).*"
    if [[ $rbversion =~ $regex ]]; then
      rbversion="${BASH_REMATCH[1]}"
      log "✅ Ruby: found $rbversion"

      return 0
    else
      log "❌ Ruby: unrecognized/unsupported ruby version:"
      log "       $rbversion"
      log ""
      if builtin command -v rbenv > /dev/null; then
        log "🔶 Ruby: detected rbenv"
        install_ruby_with_rbenv
      elif builtin command -v rvm > /dev/null; then
        log "🔶 Ruby: detected RVM"
        install_ruby_with_rvm
      else
        install_rbenv
      fi

      return 101
    fi
  else
    log "❌ Ruby: not found"
    if builtin command -v rbenv > /dev/null; then
      log "🔶 Ruby: detected rbenv"
      install_ruby_with_rbenv
    elif builtin command -v rvm > /dev/null; then
      log "🔶 Ruby: detected RVM"
      install_ruby_with_rvm
    else
      install_rbenv
    fi

    return 101
  fi
}

# -------------------------------------------------------------------------------------------------
# Bundler and gems

# Checks whether a gem with the given name is installed from the bundle.
# @param 1 - name of the gem
# @return 0 if installed, 1 otherwise
# @fail - If the Gemfile.lock cannot be found
check_gem()
{
  local name
  name="$1"

  # Check Gemfile.lock existence (failsafe)
  if [[ ! -f "Gemfile.lock" ]]; then
    fail "❌ Unable to find Gemfile.lock! Please ensure you cd to the directory of the project and run this script as ./install.sh"
  fi

  # Check whether bundler reports the gem as installed
  if bundle info "$name" 1> /dev/null 2> /dev/null; then
    return 0
  fi

  return 1
}

# Extracts the version string for the given gem from the Gemfile.
# The version is made available in the $version variable
#
# @param 1 - The name of the gem
# @return 0 if successful, the $version variable will contain the version. 1 otherwise.
extract_gem_version()
{
  local regex
  regex="    $1 \(([0-9\.]+)\)"
  version="$(grep "$1" < Gemfile.lock)"
  if [[ $version =~ $regex ]]; then
    version="${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

# Attempts to install a gem with the given name
# @param 1 - The name of the gem to install
# @param 2 - Extra information to report to the user in case of gem install failure
# @fail - If gem version cannot be found or the installation fails.
install_gem()
{
  local name
  name="$1"

  # Determine the version(s) of gem from the lockfile
  if ! extract_gem_version "$name"; then
    fail "❌ Unable to find version of $name required by the application. Please report this issue on https://github.com/codidact/qpixel"
  fi

  _header "INSTALLING GEM $(echo "$name" | tr '[:lower:]' '[:upper:]') $version"
  if ! _run "gem install $name -v $version"; then
    fail "❌ Failed to install $name gem. Please refer to the error above. $2"
  fi
  _footer
  log "✅ Ruby gems - $name: installed"
}

check_install_gem_bundler()
{
  if gem info -i bundler > /dev/null; then
    log "✅ Ruby gems - bundler: found"
    return 0
  fi

  log "❌ Ruby gems - bundler: not found, installing..."
  _header 'INSTALLING BUNDLER'
  if ! _run 'gem install bundler'; then
    fail "❌ Unable to install bundler (ruby package manager). Please refer to the error above."
  fi
  _footer
  log "✅ Ruby gems - bundler: installed"
}

# We specifically install rmagick as it requires the correct library to be installed.
check_install_gem_rmagick()
{
  if check_gem 'rmagick'; then
    log "✅ Ruby gems - rmagick: found compatible version"
    return 0
  fi

  install_gem 'rmagick' "If you skipped installing system packages, you may need to install libmagicwand-dev, imagemagick or a similar package."
}

# We specifically install mysql as it requires the correct libraries to be installed.
# Additionally, it needs a special path on Mac OS with homebrew.
check_install_gem_mysql()
{
  if check_gem 'mysql2'; then
    log "✅ Ruby gems - mysql2: found compatible version"
    return 0
  fi

  # Check homebrew, as it needs a different mysql configuration
  if builtin command -v brew > /dev/null && brew info openssl 1> /dev/null 2> /dev/null; then
    log "   Ruby gems - mysql2: detected homebrew, configuring bundler for mysql2 installation..."

    local _openssl_dir
    if ! _openssl_dir="$(brew --prefix openssl)"; then
      fail "❌ Unable to determine homebrew openssl install location. Please refer to the error above."
    fi

    if ! _run "bundle config --global build.mysql2 --with-opt-dir=\"$_openssl_dir\""; then
      fail "❌ Error while configuring bundler. Please refer to the error above."
    fi

    log "✅ Ruby gems - mysql2: configured bundler for mysql2 installation through homebrew"
  fi

  install_gem 'mysql2' "If you skipped installing system packages, you may need to install libmysqlclient-dev, mysql-devel or a similar package."
}

bundle_install()
{
  _header "INSTALLING RUBY DEPENDENCIES USING BUNDLER"
  if ! _run 'bundle install'; then
    fail "❌ Failed to install dependencies using bundler. Please refer to the error above."
  fi
  _footer
  log "✅ Ruby gems: installed all dependencies"
}

# -------------------------------------------------------------------------------------------------
# Setup

check_mysql()
{
  # TODO: Do stuff with mysql database settings
  if builtin command -v mysql > /dev/null; then
    log "✅ MySQL client: found $(mysql --version)"
  else
    log "🔶 MySQL client: not found"
  fi
}

check_redis()
{
  if command -v redis-cli > /dev/null; then
    log "✅ Redis: found $(redis-cli --version)"
  else
    log "🔶 Redis: no local installation found, checking via port..."
    if lsof -i:6379 -sTCP:LISTEN > /dev/null; then
      log "✅ Redis: seems to be accepting connections"
    else
      log "❌ Redis: Can't find a redis server on the default port."
      log "   You can set up redis by running it as a service, or by running it inside docker."
      log "TODO"
    fi

    log "TODO ask whether to continue"

  fi
}

set_up_db()
{
  log "   Setup - Database: QPixel supports MySQL and MariaDB."
  log "   Setup - Database: However, if you use MariaDB, we need to update some of the collations used."

  if ask "Are you using MariaDB/will you use MariaDB for QPixel?"; then
    log "   Setup - Database: Setting collations to be compatible with MariaDB"
    if ! sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' "db/schema.rb"; then
      fail "❌ Unable to update collations."
    fi
  else
    log "   Setup - Database: Setting collations to be compatible with MySQL"
    if ! sed -i 's/utf8mb4_unicode_ci/utf8mb4_0900_ai_ci/g' "db/schema.rb"; then
      fail "❌ Unable to update collations."
    fi
  fi

  log "✅ Setup - Database: set correct collations"
}

# -------------------------------------------------------------------------------------------------
# In-rails setup

setup_ruby_initialize()
{
  if bundle exec rails db:version 1> /dev/null 2> /dev/null; then
    log "✅ Setup: database found"
  else
    if ! _run "bundle exec rails db:create"; then
      warn "Unable to create database, it may already be created. Continuing.."
    fi
  fi

  # Check if we can query communities. If that fails, we will get an error and we will load the schema
  if bundle exec rails r "Community.any?" 1> /dev/null 2> /dev/null; then
    log "✅ Setup: schema already loaded"
  else
    if ask "Do you want to wipe the database and load the initial database schema?" && \
       ask "🔶 WARNING: If your QPixel database already contains data, this will wipe it. Are you sure?"; then
      _header 'LOADING SCHEMA'
      if ! _run "bundle exec rails db:schema:load"; then
        fail "❌ Unable to create DB schema. Please check whether you set the correct database credentials in config/database.yml"
      fi
      _footer
      log "✅ Setup: schema loaded"
    fi
  fi

  # TODO check whether schema exists?
  _header 'CREATING TAG PATH VIEW'
  if ! _run "bundle exec rails r db/scripts/create_tags_path_view.rb"; then
    fail "❌ Unable to create database view for tag paths."
  fi
  _footer
  log "✅ Setup: tag path view created"

  # Run database migrations
  _header 'RUNNING DATABASE MIGRATIONS'
  if ! _run "bundle exec rails db:migrate"; then
    fail "❌ Unable to run database migrations."
  fi
  _footer
  log "✅ Setup: ran database migrations"
}

create_community()
{
  local name domain
  while true; do
    read -p "Please enter the fully qualified domain for which you want to create a community, without http(s) and without slashes (e.g. meta.codidact.com)" -r domain
    read -p "Please enter the (user-facing) name for this community: " -r name
    ask "You want to create '$name' @ '$domain'?" || continue
    if bundle exec rails r "Community.create!(name: '$name', host: '$domain'); Rails.cache.clear"  2>&1 | head -n 2; then
      log "✅ Setup - communities: created community '$name' @ '$domain'"
      return 0
    else
      warn "❌ Failed to create community '$name' @ '$domain'. Please refer to the error above"
      return 1
    fi
  done
}

set_up_communities()
{
  if is_dev; then
    # Check whether dev community already exists
    if ! bundle exec rails r "exit(1) unless Community.where(host: 'localhost:3000').any?" 2> /dev/null; then
      log "✅ Setup - communities: found development community @ 'localhost:3000'"
    else
      log "   Setup: creating default community for development..."
      if ! _run "bundle exec rails r \"Community.create(name: 'Dev Community', host: 'localhost:3000'); Rails.cache.clear\""; then
        fail "❌ Unable to create development community. Please refer to the error above"
      fi
      log "✅ Setup - communities: created development community @ 'localhost:3000"
    fi
  else
    log "QPixel is designed for a multi-community setup."
    log "This means that a single instance of the software can host multiple, separate communities across different domains."
    log "Accounts are the same for all communities of an instance, and users can see an overview of the communities being hosted on the instance."
    log "The content, reputation and user privileges are completely separate per community."
    log ""
    log "The domain which you access in your browser is used to determine which community to serve, so it needs to be configured correctly in the application."

    local domain name
    if bundle exec rails r "exit(1) unless Community.any?" 2> /dev/null; then
      log "🔶 Setup - communities: detected existing communities:"
      bundle exec rails r "Community.all.each { |c| puts \"'#{c.name}' @ '#{c.host}'\" }" 2> /dev/null
    else
      log "🔶 Setup - communities: no communities detected - setting up first community..."
      if ! create_community; then
        fail "❌ Failed to create community"
      fi
    fi

    while ask "Do you want to set up another community?"; do
      create_community
    done

    log "🔶 Setup - communities: if you ever want to create additional communities, you can run this script again."
  fi
}

# Ensures that all communities have correct tag sets
set_up_tag_sets()
{
  # This code needs to have no indentation to work correctly
  local rails_code
  # shellcheck disable=SC2140
  rails_code=""\
"Community.all.each { |c| "\
"RequestContext.community = c; "\
"cat=Category.find_by(name: 'Meta'); "\
"cat.update!(tag_set: TagSet.find_by(name: 'Meta')) unless cat&.tag_set_id; "\
"cat=Category.find_by(name: 'Q&A'); "\
"cat.update!(tag_set: TagSet.find_by(name: 'Main')) unless cat&.tag_set_id; "\
"}"

  if ! _run "bundle exec rails r \"$rails_code\""; then
    fail "❌ Unable to set tag sets for communities. Please refer to the error above."
  fi
  log "✅ Setup - database: ensured base categories have tag sets"
}

set_up_seeds()
{
  # TODO: Ask user to seed to prevent recreation of Q&A category? (Or perhaps that is a bug that needs fixing?)
  _header "SEEDING DATABASE"
  if ! bundle exec rails r "exit(1) unless Post.unscoped.where(post_type: PostType.where(name: ['HelpDoc', 'PolicyDoc'])).any?"; then
    # No help posts detected, seed those too
    if ! _run "UPDATE_POSTS=true bundle exec rails db:seed"; then
      fail "❌ Failed to seed database (with initial posts). Please refer to the error above."
    fi
  elif ! _run "bundle exec rails db:seed"; then
    fail "❌ Failed to seed database. Please refer to the error above."
  fi
  _footer
  log "✅ Setup - database: seeded database"
}

set_up_admin_user()
{
  if ! _run "bundle exec rails r \"User.last.update(confirmed_at: DateTime.now, is_global_admin: true)\""; then
    fail "❌ Unable to create default user"
  fi
}

# -------------------------------------------------------------------------------------------------
# Actual commands

check_production

install_packages

# Check ruby if previous check reports failure (installed using this command)
while ! check_install_ruby; do
  log "🔶 Ruby: Checking again"
done

# Check nodejs
check_nodejs

# Ruby gems
check_install_gem_bundler
check_install_gem_rmagick
check_install_gem_mysql
bundle_install

# TODO Settings of DB/Redis
# TODO Start DB/Redis services
#check_mysql
#check_redis

setup_ruby_initialize
set_up_communities
set_up_tag_sets
set_up_seeds
