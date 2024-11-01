class profile::primary_server::proxy() {
	package { "privoxy": }
	file { "/etc/privoxy/config":
		ensure  => "file",
		source  => "puppet:///modules/${module_name}/primary_server/privoxy_config",
		require => Package["privoxy"]
	}
	file { "/etc/privoxy/user.filter":
		ensure  => "file",
		source  => "puppet:///modules/${module_name}/primary_server/privoxy_filters",
		require => Package["privoxy"]
	}
	file { "/etc/privoxy/user.action":
		ensure  => "file",
		source  => "puppet:///modules/${module_name}/primary_server/privoxy_actions",
		require => Package["privoxy"]
	}
	service { "privoxy":
		ensure    => "running",
		enable    => true,
		subscribe => [
			File["/etc/privoxy/config"],
			File["/etc/privoxy/user.filter"],
			File["/etc/privoxy/user.action"]
		]
	}
	file { "/sbin/privoxy_forward":
		ensure => "file",
		source => "puppet:///modules/${module_name}/primary_server/privoxy_forward",
		mode   => "0755"
	} -> file { "/etc/systemd/system/privoxy_forward.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=Privoxy forward shuffle

			[Service]
			Type=oneshot
			TimeoutStartSec=0
			ExecStart=/sbin/privoxy_forward
			|__EOF__
	} -> file { "/etc/systemd/system/privoxy_forward.timer":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=Privoxy forward shuffle timer

			[Timer]
			OnCalendar=weekly
			Persistent=true

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "privoxy_forward.timer":
		ensure => "running",
		enable => true
	}
	exec { "systemctl restart privoxy_forward.service":
		refreshonly => true,
		subscribe   => [
			File["/sbin/privoxy_forward"],
			File["/etc/privoxy/config"]
		],
		require     => Service["privoxy"],
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}


	unless "${lookup("proxy_password")}" != "" {
		warning("Set up proxy_password secret to have tinyproxy set up")
	}
	else {
		file { "/etc/tinyproxy/tinyproxy.conf":
			ensure  => "file",
			content => @("__EOF__"),
				Syslog on
				PidFile "/run/tinyproxy/tinyproxy.pid"
				User tinyproxy
				Group tinyproxy
				Port 8116
				Timeout 5
				DisableViaHeader yes
				LogLevel Critical
				Upstream http localhost:8117
				BasicAuth isaacelenbaas ${lookup("proxy_password")}
				|__EOF__
		} ~> service { "tinyproxy":
			ensure  => "running",
			enable  => true,
			require => Service["privoxy"]
		}
	}
}
