
# Released under MIT License 2017

Small perl script that is a wrapper for hping3. Logs downtime, and latency deviations to STDOUT.

Prerequisites
	sudo apt-get install hping3
Usage
	perl logtcp.pl <ip> <port> [rtt_max_in_percentage_deviation] [debug]
