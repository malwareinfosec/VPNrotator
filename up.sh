#!/bin/sh
iptables -A POSTROUTING -t nat -o tun0 -j MASQUERADE
