#!/bin/sh

cd website
source env/bin/activate
./docker_builder.py
echo Docker builder terminated with code $?. Virtual environment deactivated.

deactivate
exec $SHELL
