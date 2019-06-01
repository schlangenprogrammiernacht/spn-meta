#!/bin/sh

sudo pacman -S --needed base-devel \
    eigen \
    mariadb \
    gunicorn \
    libjpeg-turbo \
    python-django \
    python-mysqlclient \
    python-pillow \
    python-sqlparse

echo 'Dependencies from AUR:'
echo 'python-django-widget-tweaks'
echo 'mysql-connector-c++ (modded PKGBUILD as in comments)'