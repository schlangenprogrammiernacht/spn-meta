#!/bin/sh

tmux new-session -d -s spn -n gameserver -c gameserver
tmux new-window -n relayserver -c relayserver
tmux new-window -n builder -c website
tmux new-window -n website -c website
tmux a -t spn
