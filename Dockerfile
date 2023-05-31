
FROM php:7.1.3-apache
LABEL maintainer="Update by Hasiniaina Andriatsiory <hasiniaina.andriatsiory@gmail.com>"

ENV PHP_VERSION 7.1.3
COPY sources.list /etc/apt/
COPY mysql.gpg.asc /etc/apt/
RUN apt-key add /etc/apt/mysql.gpg.asc
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com AA8E81B4331F7F50 \
      && echo "Acquire::Check-Valid-Until "false";" >> /etc/apt/apt.conf \
      && apt-get update

RUN apt-get update \
      && apt-get install --force-yes -y --no-install-recommends \
      lsb-release ca-certificates apt-transport-https software-properties-common build-essential \
      apt-utils \
      curl \
      cron \
      dnsutils \
      git \
      libcurl3-dev \
      libwebp-dev \
      libxpm-dev \
      libfreetype6-dev \
      libjpeg-dev \
      libpng-dev \
      libjpeg62-turbo-dev \
      libpq-dev \
      libmcrypt-dev \
      libldb-dev \
      libicu-dev \
      libgmp-dev \
      imagemagick \
      libpspell-dev \
      libbz2-dev \
      libxml2-dev \
      libz-dev \
      libzip-dev \
      libmemcached-dev \
      libreadline-dev \
      libmemcached-tools \
      libxslt1-dev \
      linux-libc-dev \
      libyaml-dev \
      libssl-dev \
      iputils-ping \
      iproute2 \
      memcached \
      nano  \
      net-tools \
      openssh-server \
      pdftk \
      sudo \
      telnet \
      vim \
      wget \
      zlib1g-dev \
      zip 

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/local --with-jpeg-dir=/usr/local --with-webp-dir=/usr/local
RUN docker-php-ext-install -j "$(nproc)" \
      bcmath  \
      bz2 \
      calendar \
      curl \
      exif \
      ftp \
      gettext \
      gd \
      intl \
      mysqli \
      mcrypt \
      opcache \
      phar \
      pdo_mysql \
      soap \
      sockets \
      sysvmsg \
      sysvsem \
      sysvshm \
      tokenizer \
      xsl \
      zip 

# Opcode cache
RUN ( \
      echo "opcache.memory_consumption=128"; \
      echo "opcache.interned_strings_buffer=8"; \
      echo "opcache.max_accelerated_files=20000"; \
      echo "opcache.revalidate_freq=5"; \
      echo "opcache.fast_shutdown=1"; \
      echo "opcache.enable_cli=1"; \
      ) > /usr/local/etc/php/conf.d/opcache-recommended.ini

#Pecl
RUN pecl install memcached redis apcu \
      && docker-php-ext-enable redis && docker-php-ext-enable memcached && docker-php-ext-enable apcu
      
# Installation node.js
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
      && echo "deb https://deb.nodesource.com/node_12.x jessie main" > /etc/apt/sources.list.d/nodesource.list && echo "deb-src https://deb.nodesource.com/node_12.x jessie main" >> /etc/apt/sources.list.d/nodesource.list  \
      && apt update -y && apt install nodejs -y --force-yes && npm install -g yarn

#composer
RUN  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --version=1.5.0 --filename=composer

COPY tcpping /usr/bin/tcpping
RUN chmod 755 /usr/bin/tcpping

COPY init_container.sh /bin/
COPY hostingstart.html /home/site/wwwroot/hostingstart.html

RUN chmod 755 /bin/init_container.sh \
    && mkdir -p /home/LogFiles/ \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home" >> /root/.bashrc \
    && ln -s /home/site/wwwroot /var/www/html \
    && mkdir -p /opt/startup

# configure startup
COPY sshd_config /etc/ssh/
COPY ssh_setup.sh /tmp
COPY startup.sh /tmp/
RUN mkdir -p /opt/startup \
   && chmod -R +x /opt/startup \
   && mv /tmp/startup.sh /opt/startup/ \
   && chmod -R +x /opt/startup/startup.sh \
   && chmod -R +x /tmp/ssh_setup.sh \
   && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
   && rm -rf /tmp/*

ENV PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080
COPY sshd_config /etc/ssh/

ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

RUN rm -f /usr/local/etc/php/conf.d/php.ini \
   && { \
                echo 'error_log=/dev/stderr'; \
                echo 'display_errors=Off'; \
                echo 'log_errors=On'; \
                echo 'display_startup_errors=Off'; \
                echo 'date.timezone=Europe/Paris'; \
    } > /usr/local/etc/php/conf.d/php.ini

COPY core/apache2.conf /etc/apache2
COPY core/envvars /etc/apache2
RUN rm -f /etc/apache2/conf-enabled/other-vhosts-access-log.conf \
      && rm /etc/apache2/sites-enabled/000-default.conf \
    && rm /etc/apache2/sites-enabled/000-default.conf && touch /var/log/cron.log \
    && a2enmod rewrite expires headers && service apache2 restart \
    && echo "syntax on\ncolorscheme desert"  > ~/.vimrc 

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/bin/init_container.sh"]
#clean
RUN apt-get clean && rm -rf /var/cache/apt/lists