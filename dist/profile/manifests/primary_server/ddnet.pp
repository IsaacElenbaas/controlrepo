class profile::primary_server::ddnet() {
	file { "/etc/systemd/system/ddnet.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=ddnet server
			Wants=network.target
			After=network.target

			[Service]
			User=isaacelenbaas
			Group=isaacelenbaas
			WorkingDirectory=/home/isaacelenbaas/.local/share/Steam/steamapps/common/DDraceNetwork/ddnet
			ExecStart=/home/isaacelenbaas/.local/share/Steam/steamapps/common/DDraceNetwork/ddnet/DDNet-Server
			Restart=always

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "ddnet":
		ensure => "running",
		enable => true
	}
}
