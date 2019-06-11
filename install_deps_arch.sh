#!/bin/sh

if [ '$EUID' -ne 0 ]
    then echo 'This script needs to be run as root.'
    exit
fi

pacman -S --needed base-devel \
    docker \
    eigen \
    mariadb \
    libjpeg-turbo \
    python-virtualenv

echo 'Dependencies from AUR:'
echo 'python-django-widget-tweaks'
echo 'mysql-connector-c++ (modded PKGBUILD as in package comments)'
