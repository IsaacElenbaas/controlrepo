class profile::primary_server::moosefs() {
	# this belongs to root by default for some reason
	file { "/var/lib/mfs":
		ensure => "directory",
		owner  => "mfs",
		group  => "mfs"
	}
	file { "/etc/mfs/mfsmaster.cfg":
		ensure => "file",
		source => "puppet:///modules/${module_name}/primary_server/mfsmaster.cfg",
		owner  => "mfs",
		group  => "mfs",
		mode   => "0600"
	}
	file { "/etc/mfs/mfsexports.cfg":
		ensure  => "file",
		content => epp("${module_name}/primary_server/mfsexports.cfg.epp"),
		owner   => "mfs",
		group   => "mfs",
		before  => File["/etc/systemd/system/moosefs.service"]
	}
	exec { "if systemctl is-active moosefs-master; then systemctl restart moosefs-master; else true; fi":
		refreshonly => true,
		provider    => "shell",
		subscribe   => [
			File["/var/lib/mfs"],
			File["/etc/mfs/mfsmaster.cfg"],
			File["/etc/mfs/mfsexports.cfg"]
		],
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
	file { "/media/torrents":
		ensure => "directory"
	} -> file { "/etc/systemd/system/moosefs-torrents-mount.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=MooseFS torrents mount
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
			mfsmount /media/torrents -H ${lookup("primary_server_ip")[0]} \
			-o mfspreflabels=S \
			-o mfssubfolder=/Torrents \
			-o mfscachemode=YES \
			-o mfsattrcacheto=120 \
			-o mfsentrycacheto=120 \
			-o mfsdirentrycacheto=120 \
			-o mfsnoposixlocks \
			&& break; \
			sleep 1m; \
			done; \
			:'
			ExecStop=fusermount -u /media/torrents

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} ~> service { "moosefs-torrents-mount":
		enable  => true,
		require => Class["profile::base::tailscale"]
	}

	["ddnet", "docker", "gonic", "jellyfin", "node", "soulseek"].each |String $service| {
		file { "/etc/systemd/system/${service}.service.d":
			ensure => "directory"
		} -> file { "/etc/systemd/system/${service}.service.d/override.conf":
			ensure  => "file",
			content => @(__EOF__),
				[Unit]
				Requires=moosefs-mount-wait.service
				After=moosefs-mount-wait.service
				|__EOF__
			require => File["/etc/systemd/system/moosefs-mount-wait.service"]
		}
	}
	service { "docker.socket": enable => false }
}
