# Pull base image.
FROM php:7.1.3-apache
LABEL maintainer="Update by Hasiniaina Andriatsiory <hasiniaina.andriatsiory@gmail.com>"
LABEL description="This image docker contains : php7.1.3, composer1.5, apache2.4, mysqlclient, cron and more extensions php."

COPY config/php.ini /usr/local/etc/php/

COPY sources.list /etc/apt/
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com AA8E81B4331F7F50
#RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com 1587841717
RUN echo "Acquire::Check-Valid-Until "false";" >> /etc/apt/apt.conf
RUN apt-get update


RUN apt-get update \
   && apt-get install --force-yes -y --no-install-recommends \
      lsb-release ca-certificates apt-transport-https software-properties-common \
      libjpeg-dev \
      libpq-dev \
      libmcrypt-dev \
      libldb-dev \
      libicu-dev \
      libgmp-dev \
      libmagickwand-dev \
      imagemagick \
      lftp \
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
      unzip \
      zip \
      iputils-ping \
      pdftk \
      expect \
      curl \
      net-tools \
      dnsutils \
      telnet \
      wget \
      mysql-client \
      git \
      sudo \
      memcached \
      libmemcached-tools \
      libmemcached-dev \
      libpng-dev \
      libjpeg62-turbo-dev \
      libmcrypt-dev \
      libxml2-dev \
      libxslt1-dev \
      mysql-client \
      zip \
      wget \
      linux-libc-dev \
      libyaml-dev \
      zlib1g-dev \
      libpq-dev \
      bash-completion \
      libldap2-dev \
      redis-server \
      libssl-dev
	

# Install memcached for PHP 7
RUN cd /tmp && git clone https://github.com/php-memcached-dev/php-memcached.git
RUN cd /tmp/php-memcached && sudo git checkout php7 && phpize && ./configure --disable-memcached-sasl && make -j$(nproc) && make install

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
      gd \
      bz2 \
      calendar \
      ctype \
      curl \
      dom 
RUN docker-php-ext-install mysqli && docker-php-ext-install pdo_mysql
RUN docker-php-ext-install \
      xml \
      zip \
      mysqli \
      soap \
      opcache \
      sockets \
      mbstring \
      mcrypt \
      zip \
      soap \
      pdo_mysql \
      mysqli \
      xsl \
      opcache \
      calendar \
      intl \
      exif \
      pgsql \
      pdo_pgsql \
      ftp 
RUN docker-php-ext-install \
      fileinfo \
      json \
      gettext 
RUN docker-php-ext-install \
      phar \
      session 
RUN docker-php-ext-install \ 
      sysvmsg \
      sysvsem \
      sysvshm \
      tokenizer \
      bcmath  

# Install APCu extension
RUN pecl install apcu-5.1.8

COPY core/memcached.conf /etc/memcached.conf


# Installation node.js
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo "deb https://deb.nodesource.com/node_12.x jessie main" > /etc/apt/sources.list.d/nodesource.list && echo "deb-src https://deb.nodesource.com/node_12.x jessie main" >> /etc/apt/sources.list.d/nodesource.list
RUN apt update -y && apt install nodejs -y --force-yes
RUN npm install -g yarn


#yarn
RUN npm install -g yarn

# Installation of Composer
RUN pecl install memcached redis
RUN docker-php-ext-enable redis

#install redis-server
RUN apt-get -y install redis-server --force-yes
#composer
RUN  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --version=1.5.0 --filename=composer

#Cron
RUN apt-get -y install cron --force-yes
RUN touch /var/log/cron.log


#ADD core/ssmtp.conf /etc/ssmtp/ssmtp.conf
#ADD core/php-smtp.ini /usr/local/etc/php/conf.d/php-smtp.ini
COPY config/apache2.conf /etc/apache2
COPY core/envvars /etc/apache2
COPY core/other-vhosts-access-log.conf /etc/apache2/conf-enabled/
RUN rm /etc/apache2/sites-enabled/000-default.conf
# Installation of Opcode cache
RUN ( \
  echo "opcache.memory_consumption=128"; \
  echo "opcache.interned_strings_buffer=8"; \
  echo "opcache.max_accelerated_files=20000"; \
  echo "opcache.revalidate_freq=5"; \
  echo "opcache.fast_shutdown=1"; \
  echo "opcache.enable_cli=1"; \
  ) > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires && service apache2 restart

RUN service redis-server start
# Our apache volume
WORKDIR /var/www/html

# create directory for ssh keys

# Set timezone to Europe/Paris
RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Expose 80 for apache, 9000 for xdebug
EXPOSE 80

#configuser
# Create new web user for apache and grant sudo without password
RUN useradd web -d /var/www -g www-data -s /bin/bash
RUN usermod -aG sudo web
RUN echo 'web ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Add sudo to www-data
RUN echo 'www-data ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN rm -rf /var/www/html && \
  mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html && \
  chown -R web:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html && \
  chmod 775 -R /var/www/html


# create directory for ssh keys
RUN mkdir /var/www/.ssh/
RUN chown -R web:www-data /var/www/
RUN chmod -R 600 /var/www/.ssh/

# Add web .bashrc config
COPY config/bashrc /var/www/
RUN mv /var/www/bashrc /var/www/.bashrc
RUN chown www-data:www-data /var/www/.bashrc
RUN echo "source .bashrc" >> /var/www/.profile ;\
    chown www-data:www-data /var/www/.profile

# Add root .bashrc config
# When you "docker exec -it" into the container, you will be switched as web user and placed in /var/www/html
RUN echo "exec su - web" > /root/.bashrc
