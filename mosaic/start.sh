#!/bin/bash
nginx
if [ $? -ne 0 ]; then
  echo "Failed to start nginx, exiting."
  exit 1
fi
exec /mosaic.sh
