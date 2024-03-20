class profile::primary_server::internet() {
	package { "cloudflared": } -> file { "/etc/systemd/system/cloudflared-dns.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=cloudflare DOH
			Wants=network.target
			After=network.target

			[Service]
			ExecStart=cloudflared proxy-dns --port 5300
			Restart=on-failure

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} ~> service { "cloudflared-dns":
		ensure => "running",
		enable => true
	}

	# stop base internet manifest from running if pihole has not been manually set up yet
	# this manifest is marked as before it in primary_server.pp
	package { "docker": }
	-> exec { "grep pihole <(docker ps 2>&1)":
		path => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
}
