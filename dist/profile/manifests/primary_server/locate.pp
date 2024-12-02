class profile::primary_server::locate() {
	file { "/etc/systemd/system/updatedb-herd.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=Herd updatedb

			[Service]
			Type=oneshot
			TimeoutStartSec=0
			ExecStart=/sbin/mfsmanage updatedb
			|__EOF__
	} -> file { "/etc/systemd/system/updatedb-herd.timer":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=Herd updatedb timer

			[Timer]
			OnCalendar=*-*-* 3:00:00
			Persistent=true

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "updatedb-herd.timer":
		ensure => "running",
		enable => true
	}
}
