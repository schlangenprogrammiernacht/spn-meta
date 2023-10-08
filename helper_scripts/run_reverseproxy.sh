#!/bin/bash

# Reverse proxy for the /websocket
docker run -it --rm --net host -v `pwd`/helper_scripts/nginx.conf:/etc/nginx/conf.d/default.conf -v /var/www/spn/staticfiles/:/var/www/spn/staticfiles/ nginx:1-alpine
