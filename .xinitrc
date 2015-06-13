#!/bin/bash

exec openbox-session & wmpid=#!

xset s off &
xset -dpms &
x11vnc -nap -wait 30 -noxdamage -display :0 -forever &
urxvt &
chromium --kiosk --disable-hang-monitor https://app.crittercism.com/developers/overview/4fd14412067e7c1d34000021 https://app.crittercism.com/developers/overview/536c04d107229a6693000003
#chromium google.com

wait $wmpid
