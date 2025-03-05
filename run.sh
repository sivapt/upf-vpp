#!/bin/sh

pkill vpp
pkill pfcpclient
/bin/vpp -c /config/pods/vpp2.conf
sleep 10
ifconfig n41 192.11.70.1/24 up

#start pfcp client
while :
do
        n_sess=`vppctl -s /run/vpp/cli2.sock sh upf session | wc -l`
        if [ $n_sess -eq 0 ]
        then
                pkill pfcpclient
                /pfcp/pfcpclient -l 192.11.70.1:10001 -r 192.11.70.201:8805 -s /pfcp/sessions.yaml &
        fi
        sleep 1
done
