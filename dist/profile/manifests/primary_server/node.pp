class profile::primary_server::node() {
	# TODO: put RWBG in herd/NoBack
	package { "nodejs": } -> user { "node":
		ensure     => "present",
		shell      => "/sbin/nologin"
	} -> file { "/etc/systemd/system/node-ports.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=node port setup
			Wants=network.target
			After=network.target

			[Service]
			Type=oneshot
			RemainAfterExit=true
			ExecStart=bash -c '\
			iptables -t nat -A PREROUTING -p tcp --dport  80 -j REDIRECT --to-port 8094; \
			iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8095; \
			:'
			ExecStop=bash -c '\
			iptables -t nat -D PREROUTING -p tcp --dport  80 -j REDIRECT --to-port 8094; \
			iptables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8095; \
			:'
			|__EOF__
	} -> file { "/etc/systemd/system/node.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=node server
			Wants=network.target
			After=network.target
			Requires=node-ports.service
			After=node-ports.service

			[Service]
			User=node
			Group=node
			CPUQuota=200%
			# RW RWBG is 2.6G per if memory sharing breaks
			MemoryMax=12G
			WorkingDirectory=/media/node
			ExecStart=node server.js
			Restart=always

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	}
	unless find_file("/media/node") {
		warning("Set up /media/node to have its service set up")
	}
	else {
		service { "node":
			ensure    => "running",
			enable    => true,
			subscribe => File["/etc/systemd/system/node.service"]
		}
	}
}
