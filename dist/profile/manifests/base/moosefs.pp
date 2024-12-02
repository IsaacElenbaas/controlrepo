class profile::base::moosefs() {
	package { "moosefs": } -> file { "/media":
		ensure => "directory"
	} -> file { "/media/herd":
		ensure  => "directory",
		owner   => "isaacelenbaas",
		group   => "isaacelenbaas"
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
			while ! ping -c 1 -W 5 ${lookup("primary_server_ip")[0]}; do sleep 1m; done &>/dev/null; \
			}; \
			mfsmount /media/herd -H ${lookup("primary_server_ip")[0]} && break; \
			sleep 1m; \
			done; \
			:'
			ExecStop=fusermount -u /media/herd

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "moosefs-mount":
		enable  => true,
		require => Class["profile::base::tailscale"]
	} -> file { "/etc/systemd/system/moosefs-mount-wait.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=Wait for MooseFS mount
			Wants=moosefs-mount.service
			After=moosefs-mount.service

			[Service]
			Type=oneshot
			TimeoutStartSec=0
			RemainAfterExit=yes
			ExecStart=bash -c 'while ! mountpoint /media/herd &>/dev/null; do sleep 10; done'
			|__EOF__
	}
	unless "server" in $facts["roles"] {
		exec { "if [ -f /etc/systemd/system/moosefs.service ]; then systemctl disable --now moosefs.service; else true; fi":
			provider => "shell",
			path     => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
		} -> file { "/etc/systemd/system/moosefs.service":
			ensure => "absent"
		}
	}

	file { "/sbin/mfsmanage":
		ensure => "file",
		source => "puppet:///modules/${module_name}/base/mfsmanage",
		mode   => "0755"
	}
}
