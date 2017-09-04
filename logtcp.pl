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
use File::Slurp;

my $host = $ARGV[0] || 'localhost';
my $port = $ARGV[1] || '22';
my $filename = $ARGV[2] || undef;
my $rtt_max = $ARGV[3] || '60'; # in % of avg rtt
my $DEBUG = $ARGV[4] || '0';

print "Usage: ./logtcp.pl <host> <port> [filename] [rtt_max_%_of_avg] [debug]\n./logtcp.pl localhost 80 60 file.log\n" and exit(0) if $host =~ m/-h|--help/xm;

my ($dt, $down_date, $down, @avg_ms);
my $repeat = 2; my $i=0; my $last_time_of_rtt_spike = time; 

print "TCP-Pinging ${host}:${port} RTT_MAX: $rtt_max"; 
$DEBUG ? print " DEBUG 1\n" : print "\n";

while ( 1 ) {
	my $tp = `sudo hping3 -c 1 -i 2 -S -p $port $host 2>&1 `;
	
	are_you_there($tp, $i);
	check_for_rtt_spikes($tp);
	
	$i++ if $i < 5;
	sleep $repeat;
	
}

sub check_for_rtt_spikes{
	my $tp = shift;

	if ( $tp =~ m/rtt=(.*?)\sms/xm ) {
		my $ms = $1;
		my $avg_ms = 0;

		shift @avg_ms if scalar @avg_ms > 100;	
		map {$avg_ms = $avg_ms + $_ } @avg_ms;

		my $avg =  ( $avg_ms / scalar @avg_ms ) if scalar @avg_ms;
		my $a_diff = $ms - $avg 				if scalar @avg_ms;
		my $a_per = ($a_diff / $ms) * 100 		if scalar @avg_ms;

		my $lat = sprintf "%.3fms %10.3fms %10.3f", $ms , $avg , $a_per if scalar @avg_ms;

		push @avg_ms, $ms; # push after all other things to not skew the average

		print "rtt=$ms " if $DEBUG;
		defined $a_per ? printf  "avg_rtt=%.1f diff_rtt=%.1f%%\n" , $avg, $a_per : print "\n" if $DEBUG; 

		if (defined $a_per and $a_per > $rtt_max  ) {
			chomp(my $date = `date +%c`);
			my $t_rtt = time;
			my $out = sprintf "%s >>>> RTT spike of %4.1f%% , %6.3fms , avg %.3fms, last spike %5ds ago\n", $date, $a_per, $ms, $avg, ($t_rtt - $last_time_of_rtt_spike);
			print $out;
			write_file($filename, { append => 1  }, $out ) if defined $filename;
			pop @avg_ms; # Remove spike latency , as not to skew to much		
			$last_time_of_rtt_spike = time;
		}
	}
}

sub are_you_there{
	my $tp = shift;
	my $i= shift;


	if ( $tp =~ m/\s100%\s/xm ) {	# 100% packet loss
		print "." if $DEBUG;
		chomp($down_date = `date +%c`) if ! $down;
		$dt = time if ! $down;	
		$down = 1;
		
#		if ( $i <1 ) {
#			die "${host}:${port} not reachable\n";
#		}
		
	}
	
	if ( $tp =~ m/\s0%\s/xm ) {
		if ( $down   ) {
			chomp(my $date = `date +%c`);
			my $ct = time;

			my $out =  "$down_date to $date ${host}:${port} down for ". ($ct - $dt)  ."s\n";	
			print $out;

			write_file($filename, { append => 1  }, $out ) if defined $filename;

			$down = 0;
		}
	}

}
