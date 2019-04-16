#!/bin/bash

pushd gameserver
git checkout dev
git pull
git submodule update --init --recursive
popd

pushd relayserver
git checkout master
git pull
git submodule update --init --recursive
popd

pushd website
git checkout master
git pull
git submodule update --init --recursive
popd
