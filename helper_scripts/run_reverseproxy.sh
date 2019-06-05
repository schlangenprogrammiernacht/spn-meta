#!/bin/bash

# Reverse proxy for the /websocket
docker run -it --rm --net host -v `pwd`/helper_scripts/nginx.conf:/etc/nginx/conf.d/default.conf nginx:1-alpine
