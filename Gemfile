source 'https://rubygems.org'
ruby '>= 2.7', '< 4'

# Essential gems: servers, adapters, Rails + Rails requirements
gem 'coffee-rails', '~> 5.0.0'
gem 'counter_culture', '~> 3.2'
gem 'fastimage', '~> 2.2'
gem 'image_processing', '~> 1.12'
gem 'jquery-rails', '~> 4.5.0'
gem 'mysql2', '~> 0.5.4'
gem 'puma', '~> 5.6'
gem 'rails', '~> 7.0.0'
gem 'rails-html-sanitizer', '~> 1.4'
gem 'redis', '~> 4.8'
gem 'rotp', '~> 6.2'
gem 'sass-rails', '~> 6.0'
gem 'sprockets', '~> 4.1.0'
gem 'sprockets-rails', '~> 3.4', require: 'sprockets/railtie'
gem 'terser', '~> 1.1'
gem 'tzinfo-data', '~> 1.2022.3'

# Sign in
gem 'devise', '~> 4.8'
gem 'devise_saml_authenticatable', '~> 1.9'
gem 'omniauth', '~> 2.1'

# Markdown support in both directions.
gem 'commonmarker', '~> 0.23'
gem 'reverse_markdown', '~> 2.1'

# Charting stuff.
gem 'chartkick', '~> 4.2'
gem 'groupdate', '~> 6.1'

# View stuff.
gem 'diffy', '~> 3.4'
gem 'jbuilder', '~> 2.11'
gem 'rqrcode', '~> 2.1'
gem 'will_paginate', '~> 3.3'
gem 'will_paginate-bootstrap', '~> 1.0'

# AWS for S3 (image storage) and SES (emails).
gem 'aws-sdk-s3', '~> 1.61', require: false
gem 'aws-ses-v4', require: 'aws/ses'

# Task scheduler.
gem 'whenever', '~> 1.0', require: false

# Debugging, linting, testing.
gem 'awesome_print', '~> 1.9'
gem 'coveralls', '~> 0.8', require: false
gem 'rubocop', '~> 1'
gem 'rubocop-rails', '~> 2.15'

# MiniProfiler support, including stack traces & memory dumps, plus flamegraphs.
gem 'flamegraph', '~> 0.9'
gem 'memory_profiler', '~> 1.0'
gem 'rack-mini-profiler', '~> 3.0'
gem 'stackprof', '~> 0.2'

# Ruby 2.7 compatibility: thwait and e2mmap are no longer bundled with Ruby, but
# import needs thwait and ActiveSupport needs e2mmap.
gem 'e2mmap', '~> 0.1'
gem 'thwait', '~> 0.2'

# Ruby 3.0 compatibility: net-smtp is no longer bundled with Ruby
gem 'net-smtp', '~> 0.3'

# Stuff for imports
gem 'ruby-progressbar', '~> 1.11'

# Image generation
gem 'rmagick', '~> 5.0'

# Payments. Kinda important, y'know.
gem 'stripe', '~> 5.55'

# EeeMAILS!
gem 'premailer-rails', '~> 1.11'

group :test do
  gem 'minitest', '~> 5.16.0'
  gem 'minitest-ci', '~> 3.4.0'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'term-ansicolor', '~> 1.7'

  gem 'capybara', '~> 3.38'
  gem 'selenium-webdriver', '~> 4.7'
  gem 'webdrivers', '~> 5.2'
end

group :development, :test do
  gem 'byebug', '~> 11.1'
end

group :development do
  gem 'letter_opener_web', '~> 2.0'
  gem 'listen', '~> 3.7'
  gem 'spring', '~> 4.0'
  gem 'web-console', '~> 4.2'

  gem 'rbs_rails', require: false
  gem 'typeprof', require: false, git: 'git@github.com:ruby/typeprof.git', branch: 'master'
end
