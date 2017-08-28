
# Released under MIT License 2017

Small perl script that is a wrapper for tcpping. Logs downtime, and latency deviations to STDOUT.

TCPPing is made by http://www.vdberg.org/~richard/

Prerequisites
	sudo apt-get install tcptraceroute
	cd /usr/bin/
	sudo wget http://www.vdberg.org/~richard/tcpping
	sudo chmod 755 tcpping
Usage
	perl logtcp.pl <ip> <port> [rtt_max_in_percentage_deviation]
