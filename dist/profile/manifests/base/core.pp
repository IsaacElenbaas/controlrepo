class profile::base::core() {
	file { "/etc/localtime":
		ensure => "link",
		target => "/usr/share/zoneinfo/America/Chicago"
	} ~> exec { "hwclock --systohc":
		refreshonly => true,
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> package { "ntp": } -> service { "ntpd":
		ensure => "running",
		enable => true
	}

	file_line { "/etc/locale.gen":
		path  => "/etc/locale.gen",
		line  => "en_US.UTF-8 UTF-8",
		match => '^\s*#?\s*en_us.UTF-8\s+UTF-8$'
	} ~> exec { "locale-gen":
		refreshonly => true,
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> file { "/etc/locale.conf":
		ensure  => "file",
		content => "LANG=en_US.UTF-8\n"
	}

	package { "sudo": } -> exec { "groupadd -f sudo":
		path => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> file_line { "sudo_group":
		path  => "/etc/sudoers",
		line  => "%sudo   ALL=(ALL:ALL) ALL",
		match => '^\s*#?\s*%sudo\s+ALL=(ALL:ALL)\s+ALL$'
	} -> user { "isaacelenbaas":
		ensure     => "present",
		groups     => ["sudo"],
		managehome => true
	}

	package { "openssh": } -> exec { 'grep "^\S*\s\+P" <(passwd -S isaacelenbaas)':
		path => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
	-> service { "sshd":
		ensure => "running",
		enable => true
	}

	package { "fuse2": } -> file_line { "fuse_allow_other":
		path  => "/etc/fuse.conf",
		line  => "user_allow_other",
		match => '^\s*#?\s*user_allow_other$'
	}
}
