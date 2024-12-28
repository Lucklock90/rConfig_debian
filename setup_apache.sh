#! /bin/sh

# This script is used to setup apache for the project

# Check for RedHat/CentOS
if [ -f /etc/redhat-release ]; then
    HTTPDDIR=/etc/httpd/conf.d/
fi

# Check for Debian/Ubuntu (using /etc/lsb-release as a fallback for older versions)
if [ -f /etc/lsb-release ]; then
    HTTPDDIR=/etc/apache2/sites-enabled
fi

# Check for Debian 12 specifically (using /etc/os-release)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "debian" ] && [ "$VERSION_ID" = "12" ]; then
        HTTPDDIR=/etc/apache2/sites-enabled
    fi
fi

# Replace PWD in rconfig-vhost.conf
sed -i -e s+PWD+$PWD+g $PWD/rconfig-vhost.conf

# Remove existing symlink if it exists and create a new one
if [ -f $HTTPDDIR/rconfig-vhost.conf ]; then
    unlink $HTTPDDIR/rconfig-vhost.conf
fi
sudo ln -s $PWD/rconfig-vhost.conf $HTTPDDIR/rconfig-vhost.conf

# Remove default configuration files
if [ -f $HTTPDDIR/000-default.conf ]; then
    unlink $HTTPDDIR/000-default.conf
fi

# For RedHat-based systems
if [ -f /etc/redhat-release ]; then
    chown -R apache:apache $PWD
    systemctl restart httpd
fi

# For Debian-based systems
if [ -f /etc/lsb-release ] || ([ -f /etc/os-release ] && [ "$ID" = "debian" ]); then
    sudo chown -R www-data:www-data /var/www/html/rconfig
    sudo chown -R $USER:www-data /var/www/html/rconfig
    systemctl restart apache2
    sudo a2enmod rewrite
    systemctl restart apache2
fi

# Debugging Apache configurations
#if [ -f /etc/redhat-release ]; then
#    httpd -S
#fi

#if [ -f /etc/lsb-release ] || ([ -f /etc/os-release ] && [ "$ID" = "debian" ]); then
#    apache2ctl -S
#fi
