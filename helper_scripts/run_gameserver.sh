#!/bin/sh

cd gameserver
build/GameServer

echo GameServer terminated with code $?.
exec $SHELL
