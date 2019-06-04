#!/bin/bash

cd website
source env/bin/activate
./manage.py runserver
echo Webserver terminated with code $?. Virtual environment deactivated.

deactivate
exec $SHELL
