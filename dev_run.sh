#!/bin/sh

tmux new-session -d -s spn -n gameserver ./helper_scripts/run_gameserver.sh
tmux new-window -n relayserver ./helper_scripts/run_relayserver.sh
tmux new-window -n builder ./helper_scripts/run_builder.sh
tmux new-window -n website ./helper_scripts/run_dev_website.sh
tmux a -t spn
