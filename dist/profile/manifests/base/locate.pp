class profile::base::locate() {
	package { "plocate": } -> file_line { "/etc/updatedb.conf":
		path  => "/etc/updatedb.conf",
		line  => "PRUNEPATHS = \"/herd /afs /media /mnt /net /sfs /tmp /udev /var/cache /var/lib/pacman/local /var/lock /var/run /var/spool /var/tmp\"",
		match => '^PRUNEPATHS'
	}
}
