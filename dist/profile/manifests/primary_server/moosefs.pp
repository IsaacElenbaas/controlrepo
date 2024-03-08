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
		ensure => "file",
		source => "puppet:///modules/${module_name}/primary_server/mfsexports.cfg",
		owner  => "mfs",
		group  => "mfs"
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
}
