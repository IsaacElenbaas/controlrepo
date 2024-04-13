class profile::server::moosefs() {
	# can't require just the moosefs package
	require Class[::profile::base::moosefs]

	# TODO: write elsewhere - don't move disks between chunkservers without marking for removal or merge chunkservers
	# having duplicate chunks on a chunkserver is pretty iffy
	# do two hard drive chunkservers and one ssd one per system
	# check out STRICT / LOOSE / KEEP / ARCHIVE storage class (?) attributes

	$chunkservers = lookup("chunkservers")
	# may not set in node def when first setting up
	if lookup("primary_server_ip") == "127.0.0.1" or lookup("primary_server_ip") == $facts["networking"]["interfaces"]["tailscale0"]["ip"] {
		$master = "Wants=moosefs-master.service\n"
	}
	else {
		$master = ""
	}
	file { "/etc/systemd/system/moosefs.service":
		ensure  => "file",
		content => @("__EOF__"/$),
			[Unit]
			Description=MooseFS
			${master}Wants=moosefs-cgiserv.service
			${$chunkservers.reduce("") |$string, $data| { "${string}Wants=moosefs-chunkserver@${regsubst($data[0], /^[^-]*-/, "")}.service\n" }}
			[Service]
			Type=oneshot
			RemainAfterExit=true
			TimeoutStopSec=0
			ExecStart=true
			ExecStop=bash -c '\
			systemctl stop moosefs-torrents-mount 2>/dev/null || true; \
			systemctl stop moosefs-mount; \
			systemctl stop moosefs-master; \
			IFS= read -r services < <(systemctl list-units -t service -o json --no-pager | tr -d " \\t\\n"); \
			services="\$services.unit.:"; \
			while [ -n "\$services" ]; do \
			services="\$\${services#*[[:punct:]]unit[[:punct:]]:}"; \
			service="\$\${services%%%%[[:punct:]]unit[[:punct:]]:*}"; \
			[ "\$\${service#*moosefs-}" != "\$service" ] || continue; \
			[ "\$\${service::1}" = "m" ] && service="\$\${service%%%%,*}" || { \
			quote="\$\${service::1}"; service="\$\${service:1}"; service="\$\${service%%%%\$quote*}"; \
			}; \
			systemctl stop "\$service"; \
			done; \
			:'
			|__EOF__
	} -> file { "/etc/systemd/system/moosefs.timer":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=MooseFS boot startup timer

			[Timer]
			OnBootSec=5min

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "moosefs.timer":
		enable => true
	}

	file { "/herd":
		ensure => "directory"
	} -> file { "/herd/locks":
		ensure => "directory",
		owner  => "mfs",
		group  => "mfs"
	} -> file { "/etc/systemd/system/moosefs-chunkserver@.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=MooseFS %I chunkserver
			Wants=network.target
			After=network.target

			[Service]
			Type=forking
			ExecStart=/usr/sbin/mfschunkserver -c /etc/mfs/mfschunkserver-%I.cfg start
			ExecStop=/usr/sbin/mfschunkserver -c /etc/mfs/mfschunkserver-%I.cfg stop
			ExecReload=/usr/sbin/mfschunkserver -c /etc/mfs/mfschunkserver-%I.cfg reload
			# have to override entire unit because you can't clear/override PIDFile
			PIDFile=/herd/locks/%I/.mfschunkserver.lock
			Restart=on-abnormal
			|__EOF__
	}
	exec { "pacman --noconfirm -S --needed linux-headers":
		path => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> package { "zfs-dkms": } ~> exec { "modprobe zfs":
		refreshonly => true,
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> service { "zfs-import-cache.service":
		enable => true
	} -> service { "zfs-mount.service":
		enable => true
	} -> service { "zfs.target":
		enable => true
	} -> service { "zfs-import.target":
		enable => true
	}
	file { "/sbin/moosefs-format":
		ensure  => "file",
		source  => "puppet:///modules/${module_name}/server/moosefs-format",
		mode    => "0755",
		require => Exec["modprobe zfs"]
	}
	$port_indices = $chunkservers.map |$server, $disks| { $server }
	$chunkservers.each |$server, $disks| {
		file { "/etc/mfs/mfschunkserver-${regsubst($server, /^[^-]*-/, "")}.cfg":
			ensure  => "file",
			content => epp("${module_name}/server/mfschunkserver.cfg.epp", {
				"server" => regsubst($server, /^[^-]*-/, ""),
				"labels" => regsubst($server, /-.*$/, ""),
				"port"   => 9422+Integer($port_indices.index($server))
			}),
			owner   => "mfs",
			group   => "mfs",
			mode    => "0600",
			before  => File["/etc/systemd/system/moosefs.service"]
		}
		file { "/herd/locks/${regsubst($server, /^[^-]*-/, "")}":
			ensure  => "directory",
			owner   => "mfs",
			group   => "mfs",
			mode    => "0600",
			require => File["/herd/locks"],
			before  => File["/etc/systemd/system/moosefs.service"]
		}
		file { "/etc/mfs/mfshdd-${regsubst($server, /^[^-]*-/, "")}.cfg":
			ensure  => "file",
			content => epp("${module_name}/server/mfshdd.cfg.epp", { "disks" => $disks }),
			owner   => "mfs",
			group   => "mfs",
			before  => File["/etc/systemd/system/moosefs.service"]
		}
		$disks.each |$disk| {
			$real_disk = regsubst($disk, /^[*<>~]*/, "")
			file { "/herd/$real_disk":
				ensure => "directory"
			} -> exec { "moosefs-format $real_disk":
				require => File["/sbin/moosefs-format"],
				path    => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
			} -> file { "/herd/$real_disk/mfs":
				ensure => "directory",
				owner  => "mfs",
				group  => "mfs",
				before => File["/etc/systemd/system/moosefs.service"]
			}
		}
	}
}
