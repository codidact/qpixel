#!/bin/bash

# -------------------------------------------------------------------------------------------------
# Error codes
# 10 - No valid ruby present, user chose not to install ruby with this script
# 11 - No valid ruby present, installing rbenv failed
# 12 - No valid ruby present, rbenv ruby-build plugin not present or no ruby 3 version selectable
# 13 - No valid ruby present, rbenv installation of ruby 3 failed
# 16 - No valid ruby present, unable to set ruby version using rbenv
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
        read -p "$* [y/n] " -r yn
        case "$yn" in
            y|Y ) return 0;;
            n|N ) return 1;;
            * ) log "Invalid choice";;
        esac
    done
}

# Parses a YAML file using awk and sed
# Copied from StackOverflow: https://stackoverflow.com/a/21189044/14170691
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
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

## Asks to install RVM, and if user agrees continues with the installation
#install_rvm()
#{
#    log "We recommend installing Ruby using RVM"
#    if ! ask "Do you want to install RVM now?"; then
#        log "Not installing RVM"
#        return 1
#    fi
#
#    log " --- Installing RVM ---"
#    log "\curl -sSL https://get.rvm.io | bash -s stable --ruby"
#
#    return $?
#}

install_rbenv()
{
    log "We recommend installing ruby using rbenv"
    if ! ask "Do you want to install rbenv?"; then
        fail_with_code 10 "❌ Not installing rbenv. Please install ruby 3.x"
    fi

    log ""
    log " --- INSTALLING RBENV ---"
    log ""

    if ! \curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash; then
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

    log ""
    log " --- INSTALLING RUBY $latest_3 USING RBENV ---"
    log ""

    if ! rbenv install "$latest_3"; then
        fail_with_code 13 "Something went wrong with the installation. Please refer to the rbenv output above."
    fi

    log ""
    log " -----------------------------------------"
    log ""

    log "✅ Ruby - rbenv: installed ruby $latest_3"

    if rbenv local "$latest_3"; then
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

    log ""
    log " --- INSTALLING RUBY USING RVM ---"
    log ""

    if ! rvm install ruby --latest; then
        fail_with_code 15 "Something went wrong with the installation. Please refer to the rvm output above."
    fi

    log ""
    log " ----------------------------------"
    log ""
    log "✅ Ruby - rvm: installed ruby"

    if rvm --default use ruby --latest; then
        log "✅ Ruby - rvm: set installed ruby as default for QPixel"
    else
        log "❌ Ruby - rbenv: unable to set ruby $latest_3 as default for QPixel"
        fail_with_code 16 "Use \`rbenv local $latest_3\` or \`rbenv global $latest_3\` to set your current ruby version."
    fi

    return 0
}

# Checks whether ruby is installed
# If it is not installed (or the installed version is not
check_ruby()
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
            log "           $rbversion"
            log ""
            if builtin command -v rbenv > /dev/null; then
                log "🔶 Ruby: detected rbenv"
                install_ruby_with_rbenv
            elif builtin command -v rvm > /dev/null; then
                log "🔶 Ruby: detected RVM"
                install_ruby_with_rvm
            else
                log "❌ Ruby: not found"
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

check_nodejs()
{
  if builtin command -v node > /dev/null; then
      log "✅ NodeJS: found $(node --version)"
  else
      log "❌ NodeJS: not found"
      log ""
      log "   Please install NodeJS for your distribution"
      log ""
      log "   - For Debian-based / Ubuntu:"
      log ""
      log "       sudo apt install nodejs"
      log ""
      log "   - For Mac with homebrew:"
      log ""
      log "       brew install nodejs"
      exit 1
  fi
}

check_mysql()
{
    # TODO: Do stuff with mysql database settings
    if builtin command -v mysql > /dev/null; then
        log "✅ MySQL client: found $(mysql --version)"
    else
        log '🔶 MySQL client: not found'
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

# -------------------------------------------------------------------------------------------------
# Actual commands

# Check ruby if previous check reports failure (installed using this command)
while ! check_ruby; do
    log "🔶 Ruby: Checking again"
done

check_nodejs
check_mysql
check_redis
