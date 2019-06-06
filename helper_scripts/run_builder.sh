#!/bin/sh

cd website
source env/bin/activate
./manage.py docker_builder
echo Docker builder terminated with code $?. Virtual environment deactivated.

deactivate
exec $SHELL
