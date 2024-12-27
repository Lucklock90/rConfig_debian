#!/bin/sh
## deploy here in Debian /etc/profile.d/login.sh
## Set some Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
reset=$(tput sgr0)
## Change to webDir
printf '\n'
echo "${cyan}
       _____                 __  _        
      /  __ \               / _|(_)       
 _ __ | /  \/  ___   _ __  | |_  _   __ _ 
| '__|| |     / _ \ | '_ \ |  _|| | / _' |
| |   | \__/\| (_) || | | || |  | || (_| |
|_|    \____/ \___/ |_| |_||_|  |_| \__, |
                                     __/ |
                                    |___/ 

    Network Configuration Management
            Copyright $(date +'%Y')
        "
printf '\n'
printf '\n'

## Change working DIR
if [ -d /var/www/html ]; then
  cd /var/www/html
else
  cd /home
fi

# Get Linux Version
echo "${green}-- Linux Version --${reset}"
source /etc/os-release
echo "Distribution: $NAME $VERSION"
printf '\n'

# Get Apache Version
echo "${green}-- Apache Version --${reset}"
if [ -x /usr/sbin/apache2 ]; then
    /usr/sbin/apache2 -v
elif [ -x /usr/sbin/httpd ]; then
    /usr/sbin/httpd -v
else
    echo "Apache not installed"
fi
printf '\n'

# Get PHP Version
echo "${green}-- PHP Version --${reset}"
php -v >/dev/null 2>&1 || echo "PHP not installed"
php -v | awk 'NR==1'
printf '\n'

# Get MariaDB Version
if command -v mariadb &> /dev/null
then
    echo "${green}-- MariaDB Version --${reset}"
    mariadb --version | awk '{ print $3 }' | awk -F\, '{ print $1 }'
elif command -v mysql &> /dev/null
then
    echo "${green}-- MySQL Version --${reset}"
    mysql --version | awk '{ print $5 }' | awk -F\, '{ print $1 }'
else
    echo "Neither MariaDB nor MySQL is installed"
fi

printf '\n'

# Display Current Directory
current_Dir=$(pwd)
echo "${green}You are currently working in $current_Dir${reset}"
printf '\n'
printf '\n'

ls -ahl
printf '\n'
