source 'https://rubygems.org'
ruby '2.7.6'

# Essential gems: servers, adapters, Rails + Rails requirements
gem 'coffee-rails', '~> 5.0.0'
gem 'counter_culture', '~> 3.2' # Taeir: from v2 to v3 drops support for ruby 2.6
gem 'fastimage', '~> 2.2'
gem 'image_processing', '~> 1.12'
gem 'jquery-rails', '~> 4.5.0'
gem 'mysql2', '~> 0.5.4'
gem 'puma', '~> 4.3.12' # Taeir: Check migration to puma 5
gem 'rails', '~> 6.0.0'
gem 'rails-html-sanitizer', '~> 1.4'
gem 'redis', '~> 4.8'
gem 'rotp', '~> 6.2'
gem 'sass-rails', '~> 5.0' # Taeir: v6 is a wrapper around sassc-rails, which differs in behavior, verify to be working
gem 'tzinfo-data', '~> 1.2022.3'
gem 'uglifier', '>= 4.2.0'

# Sign in
gem 'devise', '~> 4.8'
gem 'omniauth', '~> 1.9' # Taeir: Should be updated to 2.0+, requires testing?

# Markdown support in both directions.
gem 'commonmarker', '~> 0.23'
gem 'reverse_markdown', '~> 2.1'

# Charting stuff.
gem 'chartkick', '~> 4.2' # Taeir: v3 -> v4 drops support for Ruby < 2.6
gem 'groupdate', '~> 6.1' # Taeir: v4 -> v6 drops support for Ruby < 2.6

# View stuff.
gem 'diffy', '~> 3.4'
gem 'jbuilder', '~> 2.11'
gem 'rqrcode', '~> 2.1'
gem 'will_paginate', '~> 3.3'
gem 'will_paginate-bootstrap', '~> 1.0' # Taeir: unmaintained, last update 7 years ago...

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
gem 'flamegraph', '~> 0.9' # Taeir: not updated for 5 years
gem 'memory_profiler', '~> 1.0'
gem 'rack-mini-profiler', '~> 3.0' # Taeir: Confirm working
gem 'stackprof', '~> 0.2'

# Ruby 2.7 compatibility: thwait and e2mmap are no longer bundled with Ruby, but
# import needs thwait and ActiveSupport needs e2mmap.
gem 'e2mmap', '~> 0.1'
gem 'thwait', '~> 0.2'

# Stuff for imports
gem 'ruby-progressbar', '~> 1.11'

# Image generation
gem 'rmagick'

# Payments. Kinda important, y'know.
gem 'stripe', '~> 5.55' # Taeir: Stripe did 2 major releases this year, but I cannot easily test whether the new versions work well. Therefore, I left this at the last v5.

# EeeMAILS!
gem 'premailer-rails', '~> 1.11'

group :test do
  gem 'minitest', '~> 5.16.0'
  gem 'minitest-ci', '~> 3.4.0'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'term-ansicolor', '~> 1.7'
end

group :development, :test do
  gem 'byebug', '~> 11.1'
end

group :development do
  gem 'letter_opener_web', '~> 2.0' # Taeir: Requires ruby 2.7 or higher
  gem 'listen', '~> 3.7'
  gem 'spring', '~> 4.0' # Taeir: Requires ruby 2.7+ and rails 6.0+
  gem 'web-console', '~> 4.2'
end
