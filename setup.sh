#!/bin/bash

set -e

packages='sudo vim htop rxvt-unicode x11vnc chromium chromium-l10n xorg openbox unclutter xdotool figlet screen wmctrl'

if [ -z "$(grep "Debian GNU/Linux 8" /etc/issue)" ]; then 
    echo "This script was only written to run on Debian Jessie. Exiting..."
    exit 1
fi

su -c "apt-get update && apt-get install $packages -y && echo \"$USER    ALL=(ALL:ALL) ALL\" >> /etc/sudoers"
echo '#!/bin/bash

get_ip() {
    ip addr | grep "inet " | grep -v "127.0.0.1" | cut -d" " -f6
}

xset s off &
xset -dpms &
x11vnc -nap -wait 30 -noxdamage -display :0 -forever &
unclutter -idle 1 -jitter 2 -root &
ip=$(get_ip)
while [ -z $ip ]; do
    ip=$(get_ip)
done
hostname=$(hostname)
urxvt  -e bash -c "echo -e \"hostname: $hostname\\nip: $ip\" | figlet; bash" &
chromium-start
sleep 15 && xdotool search --onlyvisible --class "Chromium" windowfocus key F11 &
openbox-session' > ~/.xsession
echo 'if [ -z "$SSH_CLIENT" ] || [ -z "$SSH_TTY" ]; then
    startx
fi

chromium-start () {
    export DISPLAY=:0
    links=( $(cat ~/links-to-load.txt | grep -v ^#) )
    screen -dm chromium \
      --kiosk-mode \
      --auto-launch-at-startup \
      --disable-hang-monitor \
      --disable-session-crashed-bubble \
      --disable-cache \
      --disable-canvas-aa \
      --default-tile-width=384 \
      --default-tile-height=384 \
      $( echo ${links[@]} )
}

chromium-stop () {
    export DISPLAY=:0
    wmctrl -c chromium
}' >> ~/.bashrc
echo 'https://www.google.com/' > ~/links-to-load.txt
sudo sed -i "s/ExecStart.*/ExecStart=-\/sbin\/agetty -a $USER %I $TERM/g" /etc/systemd/system/getty.target.wants/getty@tty1.service
sudo systemctl set-default multi-user.target
sudo reboot
