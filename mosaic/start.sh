#!/bin/bash
nginx -g "daemon off;" &
exec /mosaic.sh
