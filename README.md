## rpfload

rpfload is a Perl script for applying pf firewall configurations on OpenBSD with automatic rollback to a backup pf.conf file after a configurable period of time.

If you have ever made a mistake in pf.conf and locked yourself out or caused other calamity, this can be helpful.

### Rationale

You can accomplish something similar with a simple shell one-liner like this:

```
pfctl -f /etc/pf.conf && sleep 60 && pfctl -d
```

This will load /etc/pf.conf, wait 60 seconds, then disable the firewall. 

But if you don't want to totally disable PF, rpfload allows you to switch between config files a little easier than doing so in a oneliner, 
can be sent to the background with `&` and the process killed later if needed, and logs the actions it takes to the syslog,
so you can check `/var/log/messages` and see exactly which config file it ended up running, or whether it disabled PF completely. 

### Installing

To install rpfload and its man page, run:
```
# ./install.sh
```

### Usage

See the man page (rpfload.1) for full usage examples. Below is a brief explanation
to get you running. 

To reproduce the oneliner above, use the `-d` flag to disable PF on timeout:
```
# rpfload -d -f /etc/pf.conf
```
This will run `pfctl -f /etc/pf.conf`, wait 60 seconds (the default timeout length), then run `pfctl -d` if the process has not been killed before then.

You can also replace the config file with a backup on timeout. This will require a backup configuration file that will be applied after the timeout is reached. A simple usage example might look like this:
 
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

### Logs

rpfload will log what it is doing to the syslog. Check /var/log/messages
 
### Bugs

Probably.

