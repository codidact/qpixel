FROM ruby:3.0.0

# docker build -f docker/Dockerfile -t qpixel_uwsgi .

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
        libgdbm-dev && \
   apt-get install -y default-mysql-server

# Install nodejs and imagemagick
WORKDIR /opt
RUN wget https://nodejs.org/dist/v12.18.3/node-v12.18.3-linux-x64.tar.xz && \
    tar xf node-v12.18.3-linux-x64.tar.xz && \
    wget https://imagemagick.org/archive/binaries/magick && \
    chmod +x magick && \
    mv magick /usr/local/bin/magick

ENV NODEJS_HOME=/opt/node-v12.18.3-linux-x64/bin
ENV PATH=$NODEJS_HOME:$PATH

# Add core code to container
WORKDIR /code
COPY . /code
RUN gem install bundler -v 2.4.22 && \
    bundle install

EXPOSE 80 443 3000
ENTRYPOINT ["/bin/bash"]
CMD ["/code/docker/entrypoint.sh"]

