#!/bin/sh
iptables -D POSTROUTING -t nat -o tun0 -j MASQUERADE
