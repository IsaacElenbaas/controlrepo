class profile::primary_server::letsencrypt() {
	file { "/sbin/reload-certs":
		ensure  => "file",
		source  => "puppet:///modules/${module_name}/primary_server/reload-certs",
		mode    => "0755"
	}

	package { "certbot": } -> file { "/etc/systemd/system/certbot-renew.service.d":
		ensure => "directory"
	} -> file { "/etc/systemd/system/certbot-renew.service.d/override.conf":
		ensure  => "file",
		content => @(__EOF__),
			[Service]
			ExecStart=
			ExecStart=/usr/bin/certbot -q renew --post-hook "/sbin/reload-certs"
			|__EOF__
	} ~> service { "certbot-renew.timer":
		ensure => "running",
		enable => true
	}

	exec { "[ -z \"\$(certbot certificates -q)\" ] && certbot certonly -n --agree-tos --no-eff-email --email letsencrypt@isaacelenbaas.com --webroot -w /media/node/ -d isaacelenbaas.com,RWBG.isaacelenbaas.com,RWGG.isaacelenbaas.com,proxied.isaacelenbaas.com || true":
		onlyif      => "systemctl is-active node",
		require     => Package["certbot"],
		provider    => "shell",
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
}

