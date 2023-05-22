# Pull base image.
FROM php:7.1.3-apache
LABEL maintainer="Update by Hasiniaina Andriatsiory <hasiniaina.andriatsiory@gmail.com>"
LABEL description="This image docker contains : php7.1.3, composer1.5, apache2.4, mysqlclient, redis-server, cron and more extensions php."

COPY config/php.ini /usr/local/etc/php/

COPY sources.list /etc/apt/
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com AA8E81B4331F7F50 \
      && echo "Acquire::Check-Valid-Until "false";" >> /etc/apt/apt.conf \
      && apt-get update

RUN apt-get update \
      && apt-get install --force-yes -y --no-install-recommends \
      lsb-release ca-certificates apt-transport-https software-properties-common build-essential \
      libwebp-dev \
      libxpm-dev \
      libfreetype6-dev \
      libjpeg-dev \
      libpng-dev \
      libjpeg62-turbo-dev \
      libpq-dev \
      libmcrypt-dev \
      libldb-dev \
      lftp \
      libicu-dev \
      libgmp-dev \
      libmagickwand-dev \
      imagemagick \
      zlib1g-dev \
      libpspell-dev \
      libcurl3-dev \
      libbz2-dev \
      libxml2-dev \
      libz-dev \
      libzip-dev \
      libmemcached-dev \
      libreadline-dev \
      openssh-server \
      apt-utils \
      nano  \
      vim \
      zip \
      unzip \
      iputils-ping \
      pdftk \
      curl \
      net-tools \
      telnet \
      mysql-client \
      git \
      sudo \
      memcached \
      libmemcached-tools \
      libxslt1-dev \
      wget \
      linux-libc-dev \
      libyaml-dev \
      dos2unix \
      libssl-dev \
      cron 

#Install redis
RUN  wget http://download.redis.io/releases/redis-6.0.16.tar.gz \
      && tar xzf redis-6.0.16.tar.gz \
      && cd redis-6.0.16 \
      && make \
      &&  apt-get install tcl8.5 -y --force-yes \
      # optionally run "make test" to check everything is ok
      && make install \
      && cd utils \
      && yes '' | ./install_server.sh

# Install memcached for PHP 7
RUN cd /tmp && git clone https://github.com/php-memcached-dev/php-memcached.git \
      && cd /tmp/php-memcached && sudo git checkout php7 && phpize && ./configure --disable-memcached-sasl && make -j$(nproc) && make install
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/local --with-jpeg-dir=/usr/local --with-webp-dir=/usr/local
RUN docker-php-ext-install -j "$(nproc)" \
      gd \
      bz2 \
      calendar \
      ctype \
      curl \
      dom \
      mysqli \
      pdo_mysql \
      xml \
      zip \
      soap \
      sockets \
      mbstring \
      mcrypt \
      xsl \
      opcache \
      intl \
      exif \
      pgsql \
      pdo_pgsql \
      ftp \
      fileinfo \
      json \
      gettext \
      phar \
      session \ 
      sysvmsg \
      sysvsem \
      sysvshm \
      tokenizer \
      bcmath  
#Pecl
RUN pecl install memcached redis && pecl install apcu-5.1.8 \
      && docker-php-ext-enable redis
COPY core/memcached.conf /etc/memcached.conf
# Opcode cache
RUN ( \
      echo "opcache.memory_consumption=128"; \
      echo "opcache.interned_strings_buffer=8"; \
      echo "opcache.max_accelerated_files=20000"; \
      echo "opcache.revalidate_freq=5"; \
      echo "opcache.fast_shutdown=1"; \
      echo "opcache.enable_cli=1"; \
      ) > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Installation node.js
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
      && echo "deb https://deb.nodesource.com/node_12.x jessie main" > /etc/apt/sources.list.d/nodesource.list && echo "deb-src https://deb.nodesource.com/node_12.x jessie main" >> /etc/apt/sources.list.d/nodesource.list  \
      && apt update -y && apt install nodejs -y --force-yes && npm install -g yarn

#composer
RUN  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --version=1.5.0 --filename=composer

#Apache
# Our apache volume
WORKDIR /var/www/html
COPY config/apache2.conf /etc/apache2
COPY core/other-vhosts-access-log.conf /etc/apache2/conf-enabled/
RUN rm /etc/apache2/sites-enabled/000-default.conf && touch /var/log/cron.log \
      && a2enmod rewrite expires headers && service apache2 restart \
      # Set timezone to Europe/Paris
      && echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata 
#ssh
# configure startup
COPY sshd_config /etc/ssh/
COPY ssh_setup.sh /tmp
RUN mkdir -p /opt/startup \
   && chmod -R +x /opt/startup \
   && chmod -R +x /tmp/ssh_setup.sh \
   && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
   && rm -rf /tmp/*

#clean
RUN apt-get clean && rm -rf /var/cache/apt/lists

# Expose 80 for apache, 9000 for xdebug
EXPOSE 80 2222 9000