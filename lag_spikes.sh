#!/usr/bin/env bash

# The following lists contain the latency (in ms) and its duration (in seconds).
# They are processed pairwise, meaning the first element of one list corresponds 
# to the first element of the other list, and so forth.
latencies=(100 2000 300)
latency_durations=(15 25 20)

while true
do
	for i in "${!latencies[@]}"; do
		latency=${latencies[i]}
		latency_duration=${latency_durations[i]}
        # Update latency with toxiproxy-cli
        toxiproxy-cli toxic update -n latency -a latency=$latency game_proxy

        echo "Applied latency: $latency ms for $latency_duration seconds"

        # Sleep for the defined latency duration
        sleep $latency_duration
	done
done
