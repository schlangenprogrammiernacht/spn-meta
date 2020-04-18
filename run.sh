#!/bin/sh

#gameserver/docker4bots/00_setup_shm_for_test.sh
tmux new-session -d -s spn -n gameserver ./helper_scripts/run_gameserver.sh
tmux new-window -n relayserver ./helper_scripts/run_relayserver.sh
tmux new-window -n builder ./helper_scripts/run_builder.sh
tmux new-window -n website ./helper_scripts/run_dev_website.sh
#tmux new-window -n reverseproxy ./helper_scripts/run_reverseproxy.sh
tmux a -t spn
