class profile::base::moosefs() {
	package { "moosefs": } -> file { "/media":
		ensure => "directory"
	} -> file { "/media/herd":
		ensure  => "directory",
		owner   => "isaacelenbaas",
		group   => "isaacelenbaas",
		require => User["isaacelenbaas"]
	} -> file { "/etc/systemd/system/moosefs-mount.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=MooseFS mount
			Wants=network.target
			After=network.target

			[Service]
			# not oneshot to be considered started if waiting so puppet can continue
			#Type=oneshot
			#TimeoutStartSec=0
			RemainAfterExit=yes
			ExecStart=bash -c '\
			while true; do \
			while [ -f /etc/systemd/system/moosefs.service ] && ! systemctl is-active moosefs.service; do sleep 1m; done &>/dev/null || \
			{ \
			while ! systemctl is-active tailscaled.service; do sleep 1m; done &>/dev/null; \
			while ! ping -c 1 -W 5 ${lookup("primary_server_ip")}; do sleep 1m; done &>/dev/null; \
			}; \
			mfsmount /media/herd -H ${lookup("primary_server_ip")} && break; \
			sleep 1m; \
			done; \
			:'
			ExecStop=fusermount -u /media/herd

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} ~> service { "moosefs-mount":
		ensure  => "running",
		enable  => true,
		require => Class["profile::base::tailscale"]
	}
	unless "server" in $facts["roles"] {
		exec { "if [ -f /etc/systemd/system/moosefs.service ]; then systemctl disable --now moosefs.service; else true; fi":
			provider => "shell",
			path     => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
		} -> file { "/etc/systemd/system/moosefs.service":
			ensure => "absent"
		}
	}
}
