class profile::base::internet() {
	package { "dhcpcd": } -> file_line { "resolv.conf":
		path  => "/etc/dhcpcd.conf",
		line  => "nohook resolv.conf",
		match => '^\s*#?\s*nohook resolv.conf$'
	}
	service { "systemd-networkd":
		ensure => "running",
		enable => true
	}
	file { "/etc/hosts":
		ensure  => "file",
		content => epp("${module_name}/base/hosts.epp")
	}
	package { "bind": } -> file { "/etc/named.conf":
		ensure  => "file",
		content => epp("${module_name}/${lookup("named_conf")}.epp")
	} ~> service { "named":
		ensure => "running",
		enable => true
	} -> file { "/etc/resolv.conf":
		ensure  => "file",
		content => "nameserver 127.0.0.1\n",
		require => Class["profile::base::tailscale"]
	} ~> exec { "chmod -w /etc/resolv.conf; chattr +i /etc/resolv.conf":
		refreshonly => true,
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
}
