class profile::server::tty1() {
	file { "/sbin/server-tty1":
		ensure  => "file",
		content => @(__EOF__),
			#!/bin/bash

			export SHELL="/bin/bash"
			if [ "$(tty)" = "/dev/tty1" ]; then
				source /etc/profile
				source ~/.profile
				exec startx
			else
				exec /bin/bash "$@"
			fi
			|__EOF__
		mode    => "0755"
	} -> file_line { "shells_entry_for_ssh":
		path  => "/etc/shells",
		line  => "/sbin/server-tty1",
	} ~> exec { "usermod -s /sbin/server-tty1 isaacelenbaas":
		refreshonly => true,
		provider    => "shell",
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> file { "/etc/systemd/system/getty@tty1.service.d":
		ensure => "directory"
	} -> file { "/etc/systemd/system/getty@tty1.service.d/override.conf":
		ensure  => "file",
		content => @(__EOF__),
			[Service]
			ExecStart=
			ExecStart=agetty --autologin isaacelenbaas --noclear %I $TERM
			|__EOF__
	}
}
