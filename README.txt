
# Released under MIT License 2017

Small perl script that is a wrapper for hping3. Logs downtime, and latency deviations to STDOUT. Ergo no logging when things are okay.

Prerequisites
	sudo apt-get install hping3
	User running logtcp.pl must have sudo with NOPASSWD: ALL in visudo
Usage
	perl logtcp.pl <ip> <port> [rtt_max_in_percentage_deviation] [debug]
