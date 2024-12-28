#! /bin/sh

# This script is used to setup supervisor for the project

# Determine the supervisor directory based on the OS
if [ -f /etc/redhat-release ]; then
    SUPDIR=/etc/supervisord.d
fi

if [ -f /etc/lsb-release ] || [ -f /etc/os-release ]; then
    SUPDIR=/etc/supervisor/conf.d
fi

# Remove existing symlink if it exists
if [ -f $SUPDIR/horizon_supervisor.conf ]; then
    unlink $SUPDIR/horizon_supervisor.conf
fi

# Replace PWD in horizon_supervisor.ini with the current working directory
sed -i -e s+PWD+$PWD+g /var/www/html/rconfig/horizon_supervisor.ini

# Create the symlink for the Supervisor config file (pointing to the original .ini file but as .conf)
if [ -f /etc/redhat-release ]; then
    ln -s /var/www/html/rconfig/horizon_supervisor.ini $SUPDIR/horizon_supervisor.ini
fi

if [ -f /etc/lsb-release ] || [ -f /etc/os-release ]; then
    ln -s /var/www/html/rconfig/horizon_supervisor.ini $SUPDIR/horizon_supervisor.conf
fi

# Restart Supervisor service
if [ -f /etc/redhat-release ]; then
    systemctl restart supervisord
fi

if [ -f /etc/lsb-release ] || [ -f /etc/os-release ]; then
    sudo systemctl restart supervisor
fi

# Check Supervisor status
if [ -f /etc/redhat-release ]; then
    systemctl status supervisord
fi

if [ -f /etc/lsb-release ] || [ -f /etc/os-release ]; then
    sudo systemctl status horizon
fi

if [ -f /etc/lsb-release ] || [ -f /etc/os-release ]; then
    sudo supervisorctl status horizon
fi