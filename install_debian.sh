#!/bin/bash
# Setup logging
LOGFILE=install.log
# Script credit: Danie Pham
# Script credit site: https://www.writebash.com
# Script credit source: https://gitlab.com/Danny_Pham/WriteBash.com/raw/master/Install/06-Script_install_LAMP_PHP_7.2_on_CentOS_7.sh
# Script credit source: rConfig

## Set some Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

# Set the MariaDB root password from the first parameter
DBPASS="$1"

echo "${blue}Starting rConfig installation...${reset}"
sleep 1

# Function check user root
f_check_root() {
    if (($EUID == 0)); then
        # If user is root, continue to function f_sub_main
        f_sub_main
    else
        # If user not is root, print message and exit script
        echo "${red}Please use 'sudo' to run this script!${reset}"
        exit
    fi
}

# Function update os
f_update_os() {
    echo "${green}Starting OS update... Hold on a few minutes!${reset}"
    sleep 1

    sudo apt update -y

    echo ""
    echo "${green}OS update completed!${reset}"
    echo ""
    sleep 1

    # Remove needrestart (Debian 12 should not need it by default)
    sudo apt remove needrestart -y
}

f_install_base_pkgs() {
    echo "${green}Starting base package installation... Hold on a few minutes!${reset}"
    sleep 1

    sudo apt install -y build-essential curl traceroute tree zip unzip vim telnet git ufw htop dialog unzip apt-utils lsb-release apt-transport-https ca-certificates
    
    echo ""
    echo "${green}Base package installation update completed!${reset}"
    echo ""

    sleep 1
}

f_start_cron() {
    # Check if cron is already installed
    if ! command -v cron &> /dev/null; then
        echo "${red}Cron not found. Attempting to install...${reset}"
        
        # Try installing cron
        if sudo apt install -y cron; then
            echo "${green}Cron installed successfully.${reset}"
        else
            echo "${red}Failed to install cron. Exiting.${reset}"
            exit 1
        fi
    else
        echo "${green}Cron is already installed.${reset}"
    fi

    echo "${green}Starting and enabling cron service...${reset}"
    sudo systemctl start cron
    sudo systemctl enable cron

    echo "${green}Checking cron service status...${reset}"
    sudo systemctl status cron

    echo "${green}Cron installation and setup complete.${reset}"
}

f_install_redis_supervisor() {
    echo "${green}Starting redis installation... please wait!${reset}"
    sudo apt install redis-server -y
    sudo systemctl start redis-server.service
    sudo systemctl enable redis-server.service
    REDIS=$(redis-cli --version | awk '{ print $2 }' | awk -F\, '{ print $1 }')
    echo "Redis Version: $REDIS"

    echo "${green}Starting supervisor installation... please wait!${reset}"

    sudo apt install -y supervisor
    sudo service supervisor restart
    sudo systemctl enable supervisor
    SUPERVISORD=$(supervisord --version)
    echo "supervisord Version: $SUPERVISORD"
}

f_install_lamp() {

    ########## INSTALL APACHE ##########
    echo "${green}Starting LAMP Installation...${reset}"
    sleep 1
    echo "${green}Installing apache ...${reset}"

    sudo apt install -y apache2

    sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.original
    # Enable and start apache2 service
    sudo systemctl enable apache2.service
    sudo systemctl restart apache2.service

    ########## INSTALL MARIADB ##########

    # Start install MariaDB
    echo "${green}Installing MariaDB server ...${reset}"
    sleep 1
    sudo apt install -y software-properties-common
    curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=11.2
    sudo apt update -y
    sudo apt install -y mariadb-server mariadb-client

    # Enable and start mariadb service
    sudo systemctl enable mariadb
    sudo systemctl start mariadb
    sudo mariadb --version
    echo ""
    sleep 1


    ########## INSTALL PHP8.3 ##########
    PHPVER=8.3
    echo "${green}Installing PHP ${PHPVER} ...${reset}"

    # Prevent 'debconf: unable to initialize frontend: Dialog' errors during PHP install
    export DEBIAN_FRONTEND=noninteractive

    # Modificado por mi
    sudo apt update
    #sudo apt -y install lsb-release apt-transport-https ca-certificates curl build-essential
    sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    sudo echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
    sudo apt update && sudo apt upgrade -y

    sudo apt install -y php${PHPVER} php${PHPVER}-cli php${PHPVER}-gd php${PHPVER}-curl php${PHPVER}-mysql php${PHPVER}-ldap php${PHPVER}-zip php${PHPVER}-mbstring php${PHPVER}-common php${PHPVER}-ldap php${PHPVER}-gmp libapache2-mod-php${PHPVER} php${PHPVER}-xml php${PHPVER}-curl
    sudo systemctl restart apache2

    # Config to fix error Apache not loading PHP files
    sudo chmod -R 0755 /var/www/html/
    sudo chown -R www-data:www-data /var/www
    sudo sed -i '/<Directory \/>/,/<\/Directory/{//!d}' /etc/apache2/apache2.conf
    sudo sed -i '/<Directory \/>/a\    Options Indexes FollowSymLinks\n    AllowOverride All\n    Require all granted' /etc/apache2/apache2.conf

    # Restart Apache
    sudo systemctl restart apache2
    echo "${green}Finished LAMP Installation... This is great!${reset}"
    echo ""
}

# Function enable port 80,433 in IPtables
f_open_port() {
    ufw_status=$(sudo ufw status | grep -i 'Status: active')
    if [ -n "$ufw_status" ]; then
        echo "${green}Setting up the firewall for port 80 and 443 inbound!${reset}"
        sudo ufw allow ssh
        sudo ufw allow http
        sudo ufw allow https
        sudo ufw allow in "Apache Full"
        sudo ufw status verbose
        echo "${green}Completed firewall setup!${reset}"
        echo ""
    else
        echo "${red}UFW is not running!${reset}"
     fi
}

f_install_composer() {
    echo "${green}Starting composer installation... just a sec!${reset}"
    sleep 1

    cd ~
    sudo curl -sS https://getcomposer.org/installer -o composer-setup.php
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    export COMPOSER_ALLOW_SUPERUSER=1
    composer --version
    echo 'export COMPOSER_ALLOW_SUPERUSER=1' >>~/.bashrc

    export PATH=~/.config/composer/vendor/bin:$PATH
    echo 'export PATH=~/.config/composer/vendor/bin:$PATH' >>~/.bashrc

    echo ""
    echo "${green}Composer installation completed!${reset}"
    sleep 1
}

f_install_envoy() {
    echo "${green}Starting Envoy installation... just a sec!${reset}"
    sleep 1

    composer global require laravel/envoy
    echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >>~/.bashrc
    source ~/.bashrc
    envoy --version
    echo ""
    echo "${green}Envoy installation update completed!${reset}"
    sleep 1
}
 
f_service_checks() {
    echo -e "Checking software versions...\n"

    if which php >/dev/null; then
        PHPVER=$(php -v | grep --only-matching --perl-regexp "8\.\\d+\.\\d+")
        echo -e "${green}✓ PHP $PHPVER is installed!${reset}"
        echo -e "${green}✓ PHP $PHPVER is installed!${reset}" >>$LOGFILE 2>&1
    else
        echo -e "${red}✗ PHP was not installed - the script has failed"
        echo -e "${red}✗ PHP was not installed - the script has failed"
        >>$LOGFILE 2>&1
        echo -e "${red}This is needed to continue. The script will now terminate!!!${reset}"
        exit
    fi
    if which apache2 >/dev/null; then
        APACHEVER=$(apache2 -v | grep version | sed 's/.*://')
        echo -e "${green}✓ $APACHEVER is installed!${reset}"
        echo -e "${green}✓ $APACHEVER is installed!${reset}" >>$LOGFILE 2>&1
    else
        echo -e "${red}✗ APACHE was not installed - the script has failed"
        echo -e "${red}✗ This is needed to continue. The script will now terminate!!!${reset}"
        exit
    fi
    if which mariadb >/dev/null; then
        MARIADB=$(mariadb --version | awk '{ print $3 }' | awk -F\, '{ print $1 }')
        echo -e "${green}✓ MariaDB $MARIADB is installed!${reset}"
        echo -e "${green}✓ MariaDB $MARIADB is installed!${reset}" >>$LOGFILE 2>&1
    else
        echo -e "${red}✗ MariaDB was not installed - the script has failed"
        echo -e "${red}✗ MariaDB was not installed - the script has failed"
        >>$LOGFILE 2>&1
        echo -e "${red}✗ This is needed to continue. The script will now terminate!!!${reset}"
        exit
    fi

    if which redis-cli >/dev/null; then
        REDIS=$(redis-cli --version | awk '{ print $2 }' | awk -F\, '{ print $1 }')
        echo -e "${green}✓ REDIS $REDIS is installed!${reset}"
        echo -e "${green}✓ REDIS $REDIS is installed!${reset}" >>$LOGFILE 2>&1
    else
        echo -e "${red}✗ REDIS was not installed - the script has failed"
        echo -e "${red}✗ REDIS was not installed - the script has failed"
        >>$LOGFILE 2>&1
        echo -e "${red}✗ This is needed to continue. The script will now terminate!!!${reset}"
        exit
    fi
    if which supervisord >/dev/null; then
        SUPERVISORD=$(supervisord --version)
        echo -e "${green}✓ SUPERVISORD $SUPERVISORD is installed!${reset}"
        echo -e "${green}✓ SUPERVISORD $SUPERVISORD is installed!${reset}" >>$LOGFILE 2>&1
    else
        echo -e "${red}✗ SUPERVISORD was not installed - the script has failed"
        echo -e "${red}✗ SUPERVISORD was not installed - the script has failed" >>$LOGFILE 2>&1
        echo -e "${red}✗ This is needed to continue. The script will now terminate!!!${reset}"
        exit
    fi

    declare -A versions
    versions=(
        ["Cron"]="dpkg -l | grep cron"
        ["Unzip"]="unzip -v | head -n 1"
        ["Zip"]="zip -v | head -n 1"
        ["Vim"]="vim --version | head -n 1"
        ["Htop"]="htop --version | head -n 1"
    )

    for software in "${!versions[@]}"; do
        version=$(eval ${versions[$software]})
        if [ $? -eq 0 ]; then
            echo -e "${green}✓ $software: $version${reset}"
        else
            echo -e "${red}✗ $software: Not installed or error${reset}"
        fi
    done

    echo -e "\n"
}

f_deploy_login_script() {
    #sudo wget https://rawgithub.com/Lucklock90/rConfig_debian/blob/main/login_debian.sh -O /etc/profile.d/login.sh 
    sudo wget https://raw.githubusercontent.com/Lucklock90/rConfig_debian/main/login_debian.sh -O /etc/profile.d/login.sh >>$LOGFILE 2>&1

 }

f_mariadb_secure_setup() {
    echo -e "${blue}rConfig system installation is almost complete...\r"
    echo -e "Your final task will be to setup the Database Server.\r"
    echo -e "Once the Database Setup wizard is complete, Please REBOOT your server.${reset}"

    # Set the MariaDB root password from the first parameter
    # Check if the root password has been provided as a parameter
    if [ -z "$DBPASS" ]; then
        # mariadb-secure-installation
        MARIADBSETUPMSG="mariadb-secure-installation wizard"
        echo -e "The MariaDB setup wizard will now launch\r"
        echo "<<<< Start - $MARIADBSETUPMSG >>>>" >>$LOGFILE 2>&1
        
        echo "No password provided. Running mariadb-secure-installation interactively."
        sudo mariadb-secure-installation
    else
        # Automate mariadb-secure-installation
        sudo mariadb-secure-installation <<EOF
$DBPASS
$DBPASS
y
y
y
y
EOF
    fi
}

# The sub main function, use to call necessary functions of installation
f_sub_main() {
    echo "${green}OS Installation script starting...!${reset}"
    f_update_os
    f_install_base_pkgs
    f_start_cron
    f_install_redis_supervisor
    f_install_lamp
    f_open_port
    f_install_composer
    f_install_envoy
    f_service_checks
    f_deploy_login_script
    f_mariadb_secure_setup

    echo ""
    echo "${green}Installation complete, a reboot is always a good idea at this point. ${reset}"
    echo "${green}Go back to the rConfig 7 documentation and follow the instructions to configure your system!"
    echo "${green}In the future just call the service rConfig.service to start and stop your webserver, you're good to go! ${reset}"
    echo "-----------------------------------END---------------------------------"
}

f_check_root
