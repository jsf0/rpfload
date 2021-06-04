#!/usr/bin/perl
# Copyright (c) 2021 Joseph Fierro <joe@kernelpanic.life>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;

use Getopt::Long;
use Sys::Syslog qw(:DEFAULT setlogsock);
use File::Basename;
use OpenBSD::Pledge;

my $live_config;
my $backup_config;
my $time;
my $overwrite = 0;
my $disable = 0;
my $help = 0;

pledge ( qw ( rpath unix proc exec ))
    or die "Unable to pledge: $!";

GetOptions(
    "live_config|f=s" => \$live_config,
    "backup_config|b=s" => \$backup_config,
    "o" => \$overwrite,
    "d" => \$disable,
    "h" => \$help,
    "time|t=i" => \$time
) or die "Error parsing command line arguments";

if ( $help ) {
    print ( "Usage:\n\trpfload [-t seconds] [-o] -f live_config -b backup_config\n\trpfload [-t seconds] -d -f live_config\n\n" );
    exit;
}

if ( !$live_config ) {
    die "Error: no live configuration specified";
}

if ( !$backup_config && !$disable ) { 
    die "Error: no backup configuration specified";
}

if ( $disable && $overwrite ) {
    die "Error: -d and -o are mutually exclusive";
}

if ( $disable && $backup_config ) {
    die "Error: -d and -b are mutually exclusive";
}

if ( !$time ) {
    $time = 60;
}

system ( '/sbin/pfctl', '-f', $live_config);


if ( $? != 0 ) {
    die "Error: pfctl failed to load live configuration";
}

setlogsock ( "unix" );
openlog ( basename ( $0 ), "pid", "local3" );
syslog ( "warning", "loaded PF configuration at %s", $live_config );

print ( "rpfload: loaded live configuration at $live_config\n" );

if ( $disable ) {
    print ( "rpfload: disabling pf in $time seconds\n");
} else {
    print ( "rpfload: reverting to $backup_config in $time seconds.\n" );
}
print( "Kill process $$ to cancel and keep current configuration\n" );

if ( $overwrite ) {
    print ( "rpfload: overwrite requested, will replace $live_config with $backup_config unless cancelled\n" );
}

sleep ( $time );

if ( $disable ) {
    system ( "/sbin/pfctl -d" );
    if ( $? !=0 ) {
	die "Error: pfctl could not disable pf";
    }
    syslog ( "warning", "Timeout reached, disabled PF" );
    print ( "rpfload: disabled pf\n");
} else {
    system ( '/sbin/pfctl', '-f', $backup_config);
    if ( $? != 0 ) {
	die "Error: pfctl could not load backup configuration";
    }
    syslog ( "warning", "reverted configuration to backup at %s", $backup_config );
    print ( "rpfload: reverted configuration to backup at $backup_config\n" );
}

if ( $overwrite ) {
    system ( '/bin/cp', $backup_config, $live_config );
    if ($? != 0 ) {
	die "Error: failed to overwrite $live_config with $backup_config";
    }
    syslog ( "warning", "Overwrote %s with %s", $live_config, $backup_config );
    print ( "rpfload: overwrote $live_config with $backup_config\n" );
}

closelog();
