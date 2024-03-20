class profile::base::proxychains() {
	package { "proxychains-ng": } -> file { "/etc/proxychains.conf":
		ensure  => "file",
		content => epp("${module_name}/base/proxychains.conf.epp")
	}
}
