class profile::base::misc_startup() {
	file { "/media/misc-startup":
		ensure  => "file",
		owner   => "isaacelenbaas",
		group   => "isaacelenbaas",
		mode    => "0755"
	} -> file { "/etc/systemd/system/misc-startup.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=miscellaneous user startup
			Wants=network.target
			After=network.target

			[Service]
			Type=oneshot
			RemainAfterExit=true
			User=isaacelenbaas
			Group=isaacelenbaas
			ExecStart=bash /media/misc-startup
			Restart=no

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "misc-startup":
		ensure => "running",
		enable => true
	}
}
