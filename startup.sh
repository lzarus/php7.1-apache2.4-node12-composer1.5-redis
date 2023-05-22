#!/bin/sh
# Enter the source directory to make sure the script runs where the user expects
cd /home/site/wwwroot
export APACHE_PORT=80

if [  -n "$PHP_ORIGIN" ] && [ "$PHP_ORIGIN" = "php-fpm" ]; then
           export NGINX_DOCUMENT_ROOT='/home/site/wwwroot'
              service nginx start
      else
                 export APACHE_DOCUMENT_ROOT='/home/site/wwwroot'
fi
apache2-foreground;
