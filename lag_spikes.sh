#!/usr/bin/env bash

toxiproxy-cli toxic add -n latency -t latency -a latency=200 game_proxy

while true
do
	LATENCY=$(shuf -i 100-300 -n 1)
	toxiproxy-cli toxic update -n latency -a latency=$LATENCY game_proxy
	sleep 0.1
done
