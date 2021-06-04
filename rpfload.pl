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

my $live_config;
my $backup_config;
my $time;
my $overwrite = 0;
my $help = 0;

GetOptions(
    "live_config|f=s" => \$live_config,
    "backup_config|b=s" => \$backup_config,
    "o" => \$overwrite,
    "h" => \$help,
    "time|t=i" => \$time
) or die "Error parsing command line arguments";

if ( $help ) {
    print ( "Usage:\n\trpfload [-t seconds] [-o] -f live_config -b backup_config\n\n" );
    exit;
}

if ( !$live_config ) {
    die "Error: no live configuration specified";
}

if ( !$backup_config ) { 
    die "Error: no backup configuration specified";
}

if ( !$time ) {
    $time = 60;
}

system ( '/sbin/pfctl', '-f', $live_config);

if ( $? != 0 ) {
    die "Error: pfctl failed to load live configuration";
}

print ( "rpfload: loaded live configuration at $live_config\n" );
print ( "rpfload: reverting to $backup_config in $time seconds. Kill process $$ to cancel and keep current configuration\n" );

if ( $overwrite ) {
    print ( "rpfload: overwrite requested, will replace $live_config with $backup_config unless cancelled\n" );
}

sleep($time);

system ( '/sbin/pfctl', '-f', $backup_config);

if ( $? != 0 ) {
    die "Error: pfctl failed to load backup configuration";
}

print ( "rpfload: reverted configuration to backup at $backup_config\n" );

if ( $overwrite ) {
    system ( '/bin/cp', $backup_config, $live_config );
    if ($? != 0 ) {
	die "Error: failed to overwrite $live_config with $backup_config";
    }
    print ( "rpfload: overwrote $live_config with $backup_config\n" );
}
