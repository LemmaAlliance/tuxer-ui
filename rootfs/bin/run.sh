#!/bin/sh
export DISPLAY=:0
Xvfb :0 -screen 0 1024x768x24 &
sleep 1
exec /bin/main
