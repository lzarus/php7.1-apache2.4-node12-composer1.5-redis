#!/bin/bash -e
set -e

# Set the apache user and group to match the host user.
# This script will change the www-data UID/GID in the container from to 33 (default) to the UID/GID of the host user, if the current host user is not root.
OWNER=$(stat -c '%u' /var/www/html)
GROUP=$(stat -c '%g' /var/www/html)
USERNAME=www-data

[ -e "/etc/debian_version" ] || USERNAME=apache
if [ "$OWNER" != "0" ]; then
  usermod -o -u $OWNER $USERNAME
  usermod -s /bin/bash $USERNAME
  groupmod -o -g $GROUP $USERNAME
  usermod -d /var/www/html $USERNAME
  chown -R $USERNAME:$USERNAME /var/www/html
fi
echo The apache user and group has been set to the following:
id $USERNAME

usermod -d /var/www www-data

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/apache2/apache2.pid

# Start Apache in foreground
/usr/sbin/apache2 -DFOREGROUND
