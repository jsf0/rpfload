## rpfload

rpfload is a Perl script for applying pf firewall configurations on OpenBSD with automatic rollback to a backup pf.conf file after a configurable period of time.

If you have ever made a mistake in pf.conf and locked yourself out or caused other calamity, this can be helpful.

### Installing

To install rpfload and its man page, run:
```

# ./install.sh
```

### Usage

See the man page (rpfload.1) for full usage examples. Below is a brief explanation
to get you running. 

rpfload requires a live configuration file, that will be applied immediately by pfctl, and a backup configuration file, that will be applied after a user-configurable period of time (default 60 seconds). A simple usage example might look like this:
 
```
rpfload -f /etc/pf.conf -b /etc/pf.conf.backup
```

This will run `pfctl -f /etc/pf.conf`, wait 60 seconds, then run `pfctl -f /etc/pf.conf.backup`. If you Ctrl-C or kill the process' PID before the 60 seconds have passed, the current configuration will be kept and it will not revert to the backup.

rpfload will helpfully print its own PID, so you can run it in the background and kill the process later if you are happy with the config and don't want to revert.

You can also tell rpfload to overwrite the live config with the backup config file when reverting with the -o flag:

```
rpfload -o -f /etc/pf.conf -b /etc/pf.conf.backup
```

This will load /etc/pf.conf, wait 60 seconds, then load /etc/pf.conf.backup and copy /etc/pf.conf.backup to /etc/pf.conf, replacing it.. 
This is useful if you end up rebooting or run `sh /etc/netstart` and want to ensure your backup pf.conf is loaded instead of a broken one.
 
### Bugs

Probably.

