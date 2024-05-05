FROM ruby:3.1.0

ENV RUBYOPT="-KU -E utf-8:utf-8"
RUN apt-get update && \
    apt-get install -y gcc && \
    apt-get install -y make && \
    apt-get install -y \
        default-libmysqlclient-dev \
        autoconf \
        bison \
        build-essential \
        libssl-dev \
        libyaml-dev \
        libreadline-dev \
        zlib1g-dev \
        libncurses5-dev \
        libffi-dev \
        libgdbm-dev \
        nodejs \
        node-imagemagick \
        imagemagick

# Add core code to container
WORKDIR /code
COPY Gemfile Gemfile.lock /code/
RUN gem install bundler -v 2.4.22 && \
    bundle install

COPY . /code
RUN bundle exec rails assets:precompile && \
    chmod -R 0777 /code

EXPOSE 80 443 3000
ENTRYPOINT ["/bin/bash"]
CMD ["/code/docker/entrypoint.sh"]