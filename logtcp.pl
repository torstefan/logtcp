#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: logtcp.pl
#
#        USAGE: ./logtcp.pl  
#
#  DESCRIPTION: Logs the output from tcpping.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 28/08/17 11:20:47
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

my $host = $ARGV[0] || '10.10.10.2';
my $port = $ARGV[1] || '80';
my $rtt_max = $ARGV[3] || '60';


my ($dt, $down_date, $down, @avg_ms);
my $repeat = 2; my $i=0; my $last_time_of_rtt_spike = time; 

print "TCP-Pinging ${host}:${port}\n";

while ( 1 ) {
	my $tp = `tcpping -x1 -w 1 $host $port`;
	
	are_you_there($tp, $i);
	check_for_rtt_spikes($tp);
	
	$i++ if $i < 5;
	sleep $repeat;
	
}

sub check_for_rtt_spikes{
	my $tp = shift;

	if ( $tp =~ m/]\s+(.*?)\sms/xm ) {
		my $ms = $1;
		my $avg_ms = 0;

		shift @avg_ms if scalar @avg_ms > 100;	
		map {$avg_ms = $avg_ms + $_ } @avg_ms;

		my $avg =  ( $avg_ms / scalar @avg_ms ) if scalar @avg_ms;
		my $a_diff = $ms - $avg 				if scalar @avg_ms;
		my $a_per = ($a_diff / $ms) * 100 		if scalar @avg_ms;

		my $lat = sprintf "%.3fms %10.3fms %10.3f", $ms , $avg , $a_per if scalar @avg_ms;

		push @avg_ms, $ms; # push after all other things to not skew the average

		if (defined $a_per and $a_per > $rtt_max  ) {
			chomp(my $date = `date +%c`);
			my $t_rtt = time;
			printf "%s >>>> RTT spike of %4.1f%% , %6.3fms , avg %.3fms, last spike %5ds ago\n", $date, $a_per, $ms, $avg, ($t_rtt - $last_time_of_rtt_spike);
			pop @avg_ms; # Remove spike latency , as not to skew to much		
			$last_time_of_rtt_spike = time;
		}
	}
}

sub are_you_there{
	my $tp = shift;
	my $i= shift;

	if ( $tp =~ m/timeout/xm ) {
		chomp($down_date = `date +%c`) if ! $down;
		$dt = time if ! $down;	
		$down = 1;
		
		if ( $i <1 ) {
			die "${host}:${port} not reachable\n";
		}
		
	}
	
	if ( $tp !~ m/timeout/xm and $down ) {
		chomp(my $date = `date +%c`);
		my $ct = time;

		print "$down_date to $date ${host}:${port} down for ". ($ct - $dt)  ."s\n";	
		$down = 0;
	}

}
