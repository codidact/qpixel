source 'https://rubygems.org'
ruby '2.6.6'

# Essential gems: servers, adapters, Rails + Rails requirements
gem 'coffee-rails', '~> 4.2.2'
gem 'counter_culture', '~> 2.0'
gem 'fastimage', '~> 2.1'
gem 'image_processing', '~> 1.11'
gem 'jquery-rails', '~> 4.3.5'
gem 'mysql2', '~> 0.5.3'
gem 'puma', '~> 4.3.8'
gem 'rails', '~> 5.2'
gem 'rails-html-sanitizer', '~> 1.3'
gem 'redis', '~> 4.1'
gem 'rotp', '~> 6.0'
gem 'sass-rails', '~> 5.0'
gem 'tzinfo-data', '~> 1.2019.3'
gem 'uglifier', '>= 1.3.0'

# Sign in
gem 'devise', '~> 4.7'
gem 'omniauth', '~> 1.9'

# Markdown support in both directions.
gem 'commonmarker', '~> 0.21'
gem 'reverse_markdown', '~> 2.0'

# Charting stuff.
gem 'chartkick', '~> 3.4'
gem 'groupdate', '~> 4.3'

# View stuff.
gem 'diffy', '~> 3.3'
gem 'jbuilder', '~> 2.10'
gem 'rqrcode', '~> 1.1'
gem 'will_paginate', '~> 3.3'
gem 'will_paginate-bootstrap', '~> 1.0'

# AWS for S3 (image storage) and SES (emails).
gem 'aws-sdk-s3', '~> 1.61', require: false
gem 'aws-ses-v4', require: 'aws/ses'

# Task scheduler.
gem 'whenever', '~> 1.0', require: false

# Debugging, linting, testing.
gem 'awesome_print', '~> 1.8'
gem 'coveralls', '~> 0.8', require: false
gem 'rubocop', '~> 1'
gem 'rubocop-rails', '~> 2.9'

# MiniProfiler support, including stack traces & memory dumps, plus flamegraphs.
gem 'flamegraph', '~> 0.9'
gem 'memory_profiler', '~> 0.9'
gem 'rack-mini-profiler', '~> 2.0'
gem 'stackprof', '~> 0.2'

# Ruby 2.7 compatibility: thwait and e2mmap are no longer bundled with Ruby, but
# import needs thwait and ActiveSupport needs e2mmap.
gem 'e2mmap', '~> 0.1'
gem 'thwait', '~> 0.1'

# Stuff for imports
gem 'ruby-progressbar', '~> 1.10'

# Image generation
gem 'rmagick'

# EeeMAILS!
gem 'premailer-rails', '~> 1.11'

group :test do
  gem 'minitest', '~> 5.10.3'
  gem 'minitest-ci', '~> 3.4.0'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'term-ansicolor', '~> 1.7'
end

group :development, :test do
  gem 'byebug', '~> 11.1'
end

group :development do
  gem 'spring', '~> 2.1'
  gem 'web-console', '~> 3.7'
end
