#!/bin/bash -e

header() {
	echo -e "\n##### $@\n"
}

header Building GameServer
pushd gameserver
./make.sh -j4
popd

header Building RelayServer
pushd relayserver
./make.sh -j4
popd

header Setting up Django virtual environment and applying migrations
pushd website
if [ ! -e env ]; then
	python3 -m venv env
fi

source env/bin/activate
pip install -r requirements.txt
./manage.py migrate
deactivate
popd
