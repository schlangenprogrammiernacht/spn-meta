#!/bin/sh

echo "INFO: running RelayServer in endless loop."

cd relayserver
while true
do
	build/relayserver/RelayServer
	sleep 2
done

echo "Loop terminated???"
exec $SHELL
