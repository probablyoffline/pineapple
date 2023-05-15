#!/bin/bash

uci set system.led_green.trigger=default-on
uci commit system
/etc/init.d/led restart

echo "[-] killing gpsd"
pkill gpsd
echo "[-] killing kismet"
pkill kismet
echo "[-] taking down wlan1"
ifconfig wlan1 down
echo "[-] waking down wlan2"
ifconfig wlan2 down

echo "[-] starting gpsd"
gpsd -n /dev/ttyACM0

echo "[-] wait 1"
sleep 1

echo "[-] monitoring gps and waiting for sat lock"
gpspipe -w | grep -qm 1 '"mode":3'

echo "[-] parsing UTC from gpsd output"
UTCDATE=`gpspipe -w | grep -m 1 "TPV" | sed -r 's/.*"time":"([^"]*)".*/\1/' | sed -e 's/^\(.\{10\}\)T\(.\{8\}\).*/\1 \2/'`

echo "[-] set pineapple clock"
date -u -s "$UTCDATE"

echo "[-] starting wlan1 monitor"
iwconfig wlan1 mode Monitor
echo "[-] starting wlan2 monitor"
iwconfig wlan2 mode Monitor
uci set system.led_green.trigger=heartbeat
uci commit system
/etc/init.d/led restart
echo "[-] starting kismet wardrive"
kismet -p /root/kismetlogs -t wardrive --override wardrive -c wlan1 -c wlan2
