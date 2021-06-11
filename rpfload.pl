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

if ( $? != 0 ) { 
    die "Error: pfctl failed to load live configuration";
}

setlogsock ( "unix" );
openlog ( basename ( $0 ), "pid", "local3" )
    or die "Could not open syslog";

# First, check the backup file for errors, if we're using one.
# If that fails, log it and die now, because we don't want to continue
if ( !$disable ) {
    system ( '/sbin/pfctl', '-nf', $backup_config );
    if ( $? != 0 ) { 
        syslog ( "warning", "errors detected in %s, exiting without taking any action", $backup_config );
        die "Error: pfctl detected errors in $backup_config, quitting now without taking any action";
    }   
}

# We'll check the live config file for syntax errors too. 
# If that fails, die immediately because pfctl will fail to load it anyway. 
# Then, load the live config and log it.
system ( '/sbin/pfctl', '-nf', $live_config );
if ( $? != 0 ) {
    syslog ( "warning", "errors detected in %s, not loading it", $live_config );
    die "Error: pfctl detected errors in $live_config, not loading it";
} else {   
    system ( '/sbin/pfctl', '-f', $live_config);
    if ( $? != 0 ) { 
	syslog ( "warning", "pfctl failed to load %s", $live_config );
        die "Error: pfctl could not load configuration at $live_config";
    }
    syslog ( "warning", "loaded PF configuration at %s", $live_config );
    print ( "rpfload: loaded live configuration at $live_config\n" );
}

# These are just informational messages about what is about to happen
if ( $disable ) {
    print ( "rpfload: disabling pf in $time seconds\n");
} else {
    print ( "rpfload: reverting to $backup_config in $time seconds.\n" );
}

print( "Ctrl-C or kill process $$ to cancel rollback and keep current configuration\n" );

if ( $overwrite ) {
    print ( "rpfload: overwrite requested, will replace $live_config with $backup_config unless cancelled\n" );
}

# Sleep for the amount of time requested. Default is 60 seconds
sleep ( $time );

# If the user has requested to disable PF, disable it if the process is still running at this point.
# Otherwise, we will attempt to load the backup config.
if ( $disable ) {
    system ( "/sbin/pfctl -d" );
    if ( $? !=0 ) {
	syslog ( "warning", "pfctl could not disable pf, firewall still enabled" );
	die "Error: pfctl could not disable pf";
    }
    syslog ( "warning", "Timeout reached, disabled PF" );
    print ( "rpfload: disabled pf\n");
} else {
    system ( '/sbin/pfctl', '-f', $backup_config );
    if ( $? != 0 ) {
	syslog ( "warning", "pfctl could not load backup configuration at %s", $backup_config );
	die "Error: pfctl could not load backup configuration";
    }
    syslog ( "warning", "reverted PF configuration to backup at %s", $backup_config );
    print ( "rpfload: reverted PF configuration to backup at $backup_config\n" );
}

# If overwrting the config file was requested, we'll copy the backup_config to the live_config location.
if ( $overwrite ) {
    system ( '/bin/cp', $backup_config, $live_config );
    if ($? != 0 ) {
	syslog ("warning", "failed to overwrite %s with %s", $live_config, $backup_config );
	die "Error: failed to overwrite $live_config with $backup_config";
    }
    syslog ( "warning", "Overwrote %s with %s", $live_config, $backup_config );
    print ( "rpfload: overwrote $live_config with $backup_config\n" );
}

closelog();
