#!/bin/bash
cat >/etc/motd <<EOL
  _____
  /  _  \ __________ _________   ____
 /  /_\  \\___   /  |  \_  __ \_/ __ \
/    |    \/    /|  |  /|  | \/\  ___/
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/
C O N T A I N E R   A P P 
            B Y
 //        //    ///////////
 //        //    //        //
 //        //    //        //
 //        //    //        //
 //        //    ////////////
 //        //    //
 //        //    //
 //        //    //
  //////////     //

Documentation: http://aka.ms/webapp-linux
PHP quickstart: https://aka.ms/php-qs
PHP version : `php -v | head -n 1 | cut -d ' ' -f 2`
EOL
cat /etc/motd

# Get environment variables to show up in SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# starting sshd process
/usr/sbin/sshd
# starting sshd process
service ssh start
service cron start
startupCommandPath="/opt/startup/startup.sh"
$startupCommandPath
