#!/usr/bin/perl -w
use strict;
use warnings;
use XBase;
use Time::Local;
use POSIX;
use File::Copy;

my $databasefile = $ARGV[0];
my $cwd = getcwd();

# Open Database file
my $database = new XBase $databasefile;

# Get the last record number
my $end = $database->last_record;

# open updatefile
my $updatefile="$cwd/influxdb_load.csv";
unless (open(INFLUXUPD, ">>$updatefile")) { die("sub update_rrd_IO: Can not open $updatefile\n"); }

# Read each line in file
for my $i (1..$end)
{
my @fields = $database->get_record ($i);
my ($noneed, $ts, $temp, $humedity, $freeze) = @{fields};

# Calculate Unix Timestamp and round it
my $localtstemp = ($ts - 25569) * 86400 ;
my ($localts, $unused) = split /\./, $localtstemp;
my @gmtime = gmtime($localts);
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($localts);
my $unixtime = mktime ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday);
print INFLUXUPD "temperatur,ort=Keller value=$temp ${unixtime}000000000\n" ;
print INFLUXUPD "feuchtigkeit,ort=Keller value=$humedity ${unixtime}000000000\n" ;
}

close(INFLUXUPD);

move ($databasefile, "imported/$databasefile");

my $cmd = "/usr/bin/curl -i -XPOST 'http://localhost:8086/write?db=klimadaten' --data-binary \@$updatefile";
my $cmdout = qx($cmd);
