
FROM php:7.1.3-apache
LABEL maintainer="Update by Hasiniaina Andriatsiory <hasiniaina.andriatsiory@gmail.com>"

ENV PHP_VERSION 7.1.3
COPY sources.list /etc/apt/
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 3A79BD29
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
      libfreetype6-dev \
      libjpeg-dev \
      libpng-dev \
      libjpeg62-turbo-dev \
      libpq-dev \
      libmcrypt-dev \
      libldb-dev \
      libicu-dev \
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
      libssl-dev \
      iputils-ping \
      memcached \
      nano  \
      net-tools \
      openssh-server \
      pdftk \
      sudo \
      tcpdump \
      tcptraceroute \
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
#Pecl
RUN pecl install memcached redis && pecl install apcu-5.1.8 \
      && docker-php-ext-enable redis && docker-php-ext-enable memcached

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

RUN sed -i 's!ErrorLog ${APACHE_LOG_DIR}/error.log!ErrorLog /dev/stderr!g' /etc/apache2/apache2.conf
RUN sed -i 's!User ${APACHE_RUN_USER}!User www-data!g' /etc/apache2/apache2.conf
RUN sed -i 's!User ${APACHE_RUN_GROUP}!Group www-data!g' /etc/apache2/apache2.conf
RUN { \
   echo 'DocumentRoot /home/site/wwwroot'; \
   echo 'DirectoryIndex default.htm default.html index.htm index.html index.php hostingstart.html'; \
   echo 'CustomLog /dev/null combined'; \
   echo '<FilesMatch "\.(?i:ph([[p]?[0-9]*|tm[l]?))$">'; \
   echo '   SetHandler application/x-httpd-php'; \
   echo '</FilesMatch>'; \
   echo '<DirectoryMatch "^/.*/\.git/">'; \
   echo '   Order deny,allow'; \
   echo '   Deny from all'; \
   echo '</DirectoryMatch>'; \
   echo 'EnableMMAP Off'; \
   echo 'HostnameLookups Off'; \
   echo 'EnableSendfile Off'; \
   echo 'ServerSignature Off'; \
   echo 'ServerTokens Prod'; \
} >> /etc/apache2/apache2.conf

RUN rm -f /usr/local/etc/php/conf.d/php.ini \
   && { \
                echo 'error_log=/dev/stderr'; \
                echo 'display_errors=Off'; \
                echo 'log_errors=On'; \
                echo 'display_startup_errors=Off'; \
                echo 'date.timezone=Europe/Paris'; \
    } > /usr/local/etc/php/conf.d/php.ini

RUN rm -f /etc/apache2/conf-enabled/other-vhosts-access-log.conf \
      && rm /etc/apache2/sites-enabled/000-default.conf

COPY mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
RUN a2enmod rewrite

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/bin/init_container.sh"]
#clean
RUN apt-get clean && rm -rf /var/cache/apt/lists